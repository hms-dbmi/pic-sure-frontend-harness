PIC-SURE Frontend Development Harness
=====================================

This project allows you to develop frontend code for a target PIC-SURE environment without 
hosting the backend and data locally and without pushing your code up to the server to see
each change. These instructions assume you are on a Mac and that you have Docker Desktop
working. While docker-machine is generally preferable if you have significant workloads,
Docker Desktop will be sufficient for frontend stuff.

Steps to configure:

./test_using_remote_backend.sh

Then read and follow the instructions.

Issues that sometimes happen:

docker: Error response from daemon: error while creating mount source path '/host_mnt/Users/jason/avl/2021/pic-sure-frontend-harness/repos/studies-data.json': mkdir /host_mnt/Users/jason/avl/2021/pic-sure-frontend-harness/repos/studies-data.json: file exists.

If you get the above error or a similar one, restart Docker Desktop and run ./test_using_remote_backend.sh again