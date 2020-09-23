#!/bin/bash -e

#
# Activate sudosh log
# add a cron job to synchronize the sudo log
# add a cron job to synchronize dynatrace audir logs
#

ENABLE=$1
TOOL_FOLDER=$2
SERVICE_IP=$3
SERVICE_PORT=$4
LANDSCAPE_NAME=$5
RSYLOG_IP=$6
RSYSLOG_PORT=$7 

disable_audit_log()
{
    ### remove cron with sudolog.sh
    sudo bash -c '( crontab -l|grep -v sudologs) | crontab'
    ### remove cron with rsync-dynatrace-audit
    sudo bash -c '( crontab -l|grep -v rsync-dynatrace-audit) | crontab'
    ### remove the 
    ###check file exits
    
    sudo rm /etc/sudoers.d/10-all-audit-log-service || true

    #remove rsyslog forwarding configuration and restart the service
    sudo rm -f /etc/rsyslog.d/60-audit-log-service.conf
    sudo service rsyslog restart
}


########
# Start Here
########
if [ "$ENABLE" != "true" ]; then
  echo "Disable Audit logging"
  # remove audit-log cron if any
  disable_audit_log
  exit 0
fi

# Activate sudologs
sudo sed -i "s/\[LANDSCAPE\]/$LANDSCAPE_NAME/g" /opt/terraform/10-all-audit-log-service
sudo sed -i 's/\[COMPONENT\]/dynatrace/g' /opt/terraform/10-all-audit-log-service
sudo cp /opt/terraform/10-all-audit-log-service /etc/sudoers.d/

### rsyslog forwarding
sudo apt-get install rsyslog-relp -y
sudo touch /etc/rsyslog.d/60-audit-log-service.conf
echo -e "\$ModLoad omrelp" | sudo tee /etc/rsyslog.d/60-audit-log-service.conf
echo -e "*.* action(type=\"omrelp\" target=\"$RSYLOG_IP\" port=\"$RSYSLOG_PORT\" timeout=\"90\")" | sudo tee -a /etc/rsyslog.d/60-audit-log-service.conf
sudo service rsyslog restart
sudo update-rc.d rsyslog defaults

if [ ! -d /var/log/sudo-io ]; then
  sudo mkdir -p /var/log/sudo-io
  sudo chmod 777 /var/log/sudo-io
fi

# Add cron jobs if not already there
sudo bash -c "( crontab -l|grep -v agentversion ; echo  \"*/30 * * * * $TOOL_FOLDER/generate-agentversion-log.sh\") | crontab"
sudo bash -c "( crontab -l|grep -v sudologs ; echo  \"*/30 * * * * $TOOL_FOLDER/sudologs.sh -s $SERVICE_IP -p $SERVICE_PORT -d ${LANDSCAPE_NAME}_dynatrace\") | crontab"
sudo bash -c "( crontab -l|grep -v rsync-dynatrace-audit ; echo  \"*/30 * * * * $TOOL_FOLDER/rsync-dynatrace-audit.sh -s $SERVICE_IP -p $SERVICE_PORT -d ${LANDSCAPE_NAME}_dynatrace -l /opt/dynatrace-bin\") | crontab"

echo "Successfully set up audit logging crontabs"