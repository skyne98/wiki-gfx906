# How to install ROCm 7.x on Linux

The steps outlined here are based on [this](https://github.com/ROCm/ROCm/issues/4625) thread. There is also a video guide for Ubuntu 24.04 LTS [here](https://www.youtube.com/watch?v=xcI0pyE8VN8).

## Approach

AMD has stopped shipping the tensor files for gfx906 with the newer ROCm releases - despite being compatible! This is a simple workaround, wherein we can add the missing tensor files.

## ROCm Quick install

1. Go to https://rocm.docs.amd.com/projects/install-on-linux/en/latest/install/quick-start.html and copy & paste the outlined commands.

2. During the installation, you may be prompted to add a key if you have secure boot enabled.

3. After completing the install, do NOT reboot yet.

## Getting the missing tensor files

The missing tensor files can be found in the arch repository here: https://archlinux.org/packages/extra/x86_64/rocblas/
Despite being for ROCm 6.4 it'll work:

1. Download the rocblas file: https://archlinux.org/packages/extra/x86_64/rocblas/download/

2. Go to the location you downloaded it to and extract it:

  ```
  cd Downloads/ && unzstd rocblas-6.4.4-1-x86_64.pkg.tar.zst
  ```

3. There should be two folders, `opt/` and `usr/`

4. Copy all the files containing the string "gfx906" to ´/opt/rocm/lib/rocblas/library´ (sudo privileges required):

  ```
  sudo cp opt/rocm/lib/rocblas/library/*gfx906* /opt/rocm/lib/rocblas/library
  ```

5. Now reboot

6. If you enrolled a key for secure boot, you will get a blue screen with some options. Select "Enroll MOK" and type in the password you assigned earlier.

7. Check if it worked by running ´sudo update-alternatives --display rocm`

## Post-install (https://rocm.docs.amd.com/projects/install-on-linux/en/latest/install/post-install.html)

1. Configure the system linker by specifying where to find the shared objects (.so files) for ROCm applications:
```
sudo tee --append /etc/ld.so.conf.d/rocm.conf <<EOF
/opt/rocm/lib
/opt/rocm/lib64
EOF
sudo ldconfig
```

2. Add the paths to your bash
```
echo 'export PATH=$PATH:/opt/rocm-7.2.0/bin' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/opt/rocm-7.2.0/lib' >> ~/.bashrc
source ~/.bashrc
```

### That's it, enjoy!
