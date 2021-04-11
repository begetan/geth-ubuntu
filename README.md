# geth-ubuntu
How to install and update Geth on Ubuntu

### System requirements for Geth Ethereum node
| Resource | Testnet minimal  | Testnet recommended | Mainnet minimal  | Mainnet recommended |
|----------|------------------|---------------------|------------------|---------------------|
| Memory   | 4 GB _*_         | 8 GB                | 8 GB             | 16 GB               |
| CPU      | 1 Cores          | 2 Cores             | 2 Cores          | 4 Cores             |
| SSD Disk | 50 GB            | 50 GB               | 200 GB _**_      | 500 GB for hot data |
| HDD Disk |                  |                     | 200 GB _**_      | 500 GB for ancient  |
| Network  | 5 Mbps Up/Down   | 50 Mbps Up/Down     | 10  Mbps Up/Down | 100 Mbps Up/Down    |

_*_ Require `--cache=512` option

_**_ It is possible to separate ancient directory from hot cache with `--datadir.ancient` options:

After the initial fast sync of the full node, the data size is growing faster, so it recommended to truncate the blockchain periodically


### Deployment in Ubuntu
This script can be used for download and deployment on *Ubuntu 20.04* or *18.04*

Download script, check [https://geth.ethereum.org/downloads/](https://geth.ethereum.org/downloads/)

Modify `geth_version`, `geth_commit`, `geth_hash`. Unfortunatelly Geth developeres not provide *the latest* links, so you have to set all manually.

```bash
wget https://raw.githubusercontent.com/begetan/geth-ubuntu/master/geth-install.sh
chmod +x geth-install.sh
sudo ./geth-install.sh
```

### Update
For updates, you may run the same script. It will check the existence of the Geth data directory and will not overwrite configs.