#!/bin/bash
sudo apt-get update 
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az login --identity