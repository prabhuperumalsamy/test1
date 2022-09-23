The folder are created as per environment ( live, prod, test) and application kustomize configuration has been created accordingly
  eg: test (folder ) // The folder is created to store test configuration files of each application 
        efiler (folder) //The folder contains the kustomization scripts and required files for test efiler application
            kustomize.yaml (file) // The file contains the below details
                                  //1. The file contains the image which is going to be deployed in test efiler application
                                  //2. The information about which file need to be called for execution (arn_efiler.yaml) for execution
                                  //3. The details about the target file the kustomize updated information need to be passed.
            arn.yaml(file)        // The contains the details about the ARN value that need to be updated in deployment file
