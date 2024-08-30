#!/usr/bin/env bash

if gpuuuids=$(timeout -s SIGKILL 10 nvidia-smi --format=csv,noheader --query-gpu=uuid); then
  for gpuuuid in $gpuuuids; do
    if persmode=$(timeout -s SIGKILL 10 nvidia-smi --format=csv,noheader --query-gpu=persistence_mode -i $gpuuuid); then
      drain=0
      if [[ "$persmode" == "Enabled" ]]; then
        if timeout -s SIGKILL 10 sudo nvidia-smi -i $gpuuuid -pm 0; then
          echo "Disabled persistence mode"
          drain=1
        else
          echo "Persistence mode disable failed"
        fi
      else
        echo "Persistence disabled, marking for drain"
        drain=1
      fi

      if [[ $drain -eq 1 ]]; then
        if gdomain=$(timeout -s SIGKILL 10 nvidia-smi --format=csv,noheader --query-gpu=pci.domain -i $gpuuuid); then
          gdomain="${gdomain#0x}"
          if gbus=$(timeout -s SIGKILL 10 nvidia-smi --format=csv,noheader --query-gpu=pci.bus -i $gpuuuid); then
            gbus="${gbus#0x}"
            if gdevice=$(timeout -s SIGKILL 10 nvidia-smi --format=csv,noheader --query-gpu=pci.device -i $gpuuuid); then
              gdevice="${gdevice#0x}"
              pciid=$gdomain:$gbus:$gdevice.0
              echo "Draining PCI ID: $pciid"
              if ! drainout=$(timeout -s SIGKILL 10 sudo nvidia-smi drain -p $pciid -m 1); then
                echo "Drain failed for node, PCI ID: $pciid"
                echo "Output: $drainout"
              fi
            else
              echo "NVIDIA PCI device query failed, could not drain GPU"
            fi
          else
            echo "NVIDIA PCI bus query failed, could not drain GPU"
          fi
        else
          echo "NVIDIA PCI domain query failed, could not drain GPU"
        fi
      fi
    else
      echo "NVIDIA persistence mode query failed, could not drain $gpuuuid"
    fi
  done
fi

