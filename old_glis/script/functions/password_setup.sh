#!/bin/bash

password_setup() {
clear
passwd
while [ ${?} -ne 0 ] ; do
   passwd
done
return 0
}