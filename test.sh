 #!/bin/bash   
echo " ========================= "
    echo " Server Health Report "
   echo " ========================="

 timestamp=$(date) 
 echo " Timestamp : $timestamp"
host_name=$(hostname )
 echo " Hostname : $host_name" 

 echo "CPU Usage"
  cpu_use=100-$(iostats)
