PIC-SURE Frontend Development Harness
=====================================

This project allows you to develop frontend code for a target PIC-SURE environment without 
hosting the backend and data locally and without pushing your code up to the server to see
each change. These instructions assume you are on a Mac and that you have Docker Desktop
working. While docker-machine is generally preferable if you have significant workloads,
Docker Desktop will be sufficient for frontend stuff.

### Preface
Before starting, ensure that you have set up your PIC-SURE All-In-One virtual box environment with a bridge network, 
that you can navigate to your PIC-SURE environment using the IP Address on your virtual box and have logged in. 
Additionally, note that this guide was created for the macOS.

### Guide
1. Visit your virtualbox PIC-SURE All-In-One page, inspect, and open the network tab.
    1. Reload the page to allow the network tab to populate.
    2. Search for and download `settings.json`.
2. Open the browser certificates for the current page and download `picsure.local.cert`.
    1. Add `picsure.local.cert` to your local security chain.
        1. Double-click on the `picsure.local` in your security chain.
        2. Expand the `Trust` section.
        3. Select  `When using this certificate: Always Trust`.
3. Clone the frontend harness: `git clone https://github.com/hms-dbmi/pic-sure-frontend-harness.git` 
   1. Navigate into the pic-sure-frontend-harness `cd pic-sure-frontend-harness`

4. Navigate to `pic-sure-frontend-harness/repos` and `git clone https://github.com/hms-dbmi/baseline-pic-sure`

5. Move the `settings.json` file that was downloaded previously into the `$(pwd)/pic-sure-frontend-harness/repos/base_settings/` directory. <b>Note</b>: If the directory `base_settings` does not exist create it.

6. Navigate to pic-sure-frontend-harness/repos and clone the baseline-pic-sure repository by running git clone https://github.com/hms-dbmi/baseline-pic-sure.

7. Open `test_using_remote_backend.sh` with a text editor and add the following lines to the top of the file, but just below `#!/bin/bash`:
    ```
    export BACKEND_HOST=picsure.local
    export BACKEND_IP=<YOUR VIRTUALBOX IP ADDRESS>
    export PROJECT_SPECIFIC_UI_PATH=repos/baseline-pic-sure/ui  
    
    export ADDITIONAL_VOLUMES=" -v $(pwd)/repos/base_settings/settings.json:/usr/local/apache2/htdocs/picsureui/settings/settings.json "
    ```
   
8. Open your host file: `vim /private/etc/hosts`
    1. Modify the file to remove or comment out your previous
       `<virtualbox IP Address> picsure.local`
       1. Add a new record to reflect the following: `127.0.0.1 picsure.local`. The file should look similar to the following lines:
           ```
           # PIC-SURE All-In-One Virtualbox IP Address
           #192.168.1.63   picsure.local
        
           # PIC-SURE UI Harness
           127.0.0.1       picsure.local
           ```

9. In the pic-sure-all-in-one directory run the `test_using_remote_backend.sh` script and wait for it to complete.

10. Navigate to the `cert` directory.
     1. Add `localhost.ca.pem` to your local security chain.
         1. Double-click on the `localhost.ca`. In your security chain.
         2. Expand the `Trust` section.
         3. Select  `When using this certificate: Always Trust`
       
11. Clear your browser cache and restart it. Navigate to `picsure.local` and it should now correctly use the frontend harness.

### Debugging

docker: Error response from daemon: error while creating mount source path '/host_mnt/Users/jason/avl/2021/pic-sure-frontend-harness/repos/studies-data.json': mkdir /host_mnt/Users/jason/avl/2021/pic-sure-frontend-harness/repos/studies-data.json: file exists.

If you get the above error or a similar one, restart Docker Desktop and run ./test_using_remote_backend.sh again
