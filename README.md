# Arch linux install script

This is mi arch linux install script with mi config for download in new instalations. I use the best defaults configs i know for install arch. U can test it or change defautl values inside the script.

## Getting Started

These instructions will get you a copy of the project. There is higth recomended to run this script on virtual machines or on system instalations after booting the arch install cd. Do not run the script on runing systems. The script can format your entore disk if u dont know what are u doing.

### Installing
git clone https://github.com/VielLosero/arch-install.git                                                                                         

```shell
root@kali:~# git clone https://github.com/VielLosero/arch-install.git                                                                                         
Clonando en 'arch-install'...                                                                                                                                 
remote: Enumerating objects: 26, done.                                                                                                                        
remote: Counting objects: 100% (26/26), done.                                                                                                                 
remote: Compressing objects: 100% (11/11), done.                                                                                                              
remote: Total 26 (delta 14), reused 26 (delta 14), pack-reused 0                                                                                              
Desempaquetando objetos: 100% (26/26), listo.   
```

## Running the script

After cloning the repository change to arch-install dir and run the script 

```shell
root@kali:~# cd arch-install/                                                                                                                                 
root@kali:~/arch-install# ./install-archlinux.sh                                                                                                              
                                                                                                                                                              
```

#### Output While Running

```shell
---------------------------------------------------------
 Viel arch linux install script version 0.2
---------------------------------------------------------
 
 [0] autoinstall base system with default values
 [1] keyboard
 [2] set up net
 [3] partition disk
 [4] install base system
 [5] install extra packages
 [6] post install
 
 [q] quit/exit
 
=========================================================
 enter a option [0-6] or [q]: 
```

## Contributing and support

Please read [Contributor covenant](https://www.contributor-covenant.org/) for details, and  [code of conduct](https://www.contributor-covenant.org/version/2/0/code_of_conduct) before submitting pull requests or issues.

If you want to support this project with a donation, here is mi Bitcoin address:

1LMJZcpJiHkiYiHrqUZdmbHJyUvF5KUsdq

All donations are appreciated!

## Author

* **Viel Losero** - *Initial work* - [Viel Losero](https://github.com/VielLosero)

## License

This project is licensed under the BSD License - see the [LICENSE.md](LICENSE.md) file for details


