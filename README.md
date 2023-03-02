PIC-SURE Frontend Development Harness
=====================================

This project allows you to develop frontend code for a target PIC-SURE environment without 
hosting the backend and data locally and without pushing your code up to the server to see
each change. These instructions assume you are on a Mac and that you have Docker Desktop
working. While docker-machine is generally preferable if you have significant workloads,
Docker Desktop will be sufficient for frontend stuff.

### Preface
Before starting, note that this guide was created for the macOS.

### Guide
1. Clone the frontend harness: `git clone https://github.com/hms-dbmi/pic-sure-frontend-harness.git` 
   - Navigate into the pic-sure-frontend-harness `cd pic-sure-frontend-harness`

1. Navigate to `pic-sure-frontend-harness/repos` and `git clone https://github.com/hms-dbmi/baseline-pic-sure`

1. Move the `settings.json` file that was downloaded previously into the `$(pwd)/pic-sure-frontend-harness/repos/base_settings/` directory. <b>Note</b>: If the directory `base_settings` does not exist create it.

1. Navigate to `pic-sure-frontend-harness/repos` and clone the baseline-pic-sure repository by running `git clone https://github.com/hms-dbmi/baseline-pic-sure`.

1. Open `test_using_remote_backend.sh` with a text editor and add the following lines to the top of the file, but just below `#!/bin/bash`:
    ```
    export BACKEND_HOST=<set to the domain name of the environment you are using as a backend>
    
    # Set BACKEND_IP to a different IP if you don't want to hit the public DNS target for $BACKEND_HOST
    export BACKEND_IP=<IP Address>
   
    # PROJECT_SPECIFIC_UI_PATH must be set to theß path for the maven project for UI overrides. 
    # This path should be relative to the repos directory where you cloned the project specific
    # overrides repo.
    # Example export PROJECT_SPECIFIC_UI_PATH=repos/baseline-pic-sure/ui
    export PROJECT_SPECIFIC_UI_PATH=<Relative Path>  

    # If your specific environment has files that the UI normally gets out of band,
    # this is where you can add them. 
    # It is usually best to place them in the repos directory so they don't
    # end up getting checked into git.
    # Set \$ADDITIONAL_VOLUMES to a list of space separated -v arguments for the docker run command.
    # Example: export ADDITIONAL_VOLUMES="-v $(pwd)/repos/studies-data.json:/usr/local/apache2/htdocs/picsureui/studyAccess/studies-data.json"
    #          export ADDITIONAL_VOLUMES="-v $(pwd)/repos/path_a:/usr/local/apache2/htdocs/path_a -v $(pwd)/path_b:/usr/local/apache2/htdocs/path_b"
    export ADDITIONAL_VOLUMES="" 
   ```
   
1. Open your host file: `vim /private/etc/hosts`
   1. Add a new record to reflect the following: <br />
        ```
      # PIC-SURE UI Harness
      127.0.0.1       <local host name>
        ```

1. In the pic-sure-all-in-one directory run the `test_using_remote_backend.sh` script and wait for it to complete.

1. Navigate to the `pic-sure-frontend-harness/cert` directory.
     1. Add `localhost.ca.pem` to your local security chain.
         1. Double-click on the `localhost.ca`. In your security chain.
         1. Expand the `Trust` section.
         1. Select  `When using this certificate: Always Trust`
       
1. Clear your browser cache and restart it. Navigate to `<local host name>` and it should now correctly use the frontend harness.

### Debugging

docker: Error response from daemon: error while creating mount source path '/host_mnt/Users/jason/avl/2021/pic-sure-frontend-harness/repos/studies-data.json': mkdir /host_mnt/Users/jason/avl/2021/pic-sure-frontend-harness/repos/studies-data.json: file exists.

If you get the above error or a similar one, restart Docker Desktop and run ./test_using_remote_backend.sh again
