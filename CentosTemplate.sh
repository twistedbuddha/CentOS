# Template for Centos 7.3
# Deployment of this script is in two parts as a reboot is required after the O/S update due to a likely kernel update (old kernels will be removed during part 2)

# Part 1
# Update OS
yum makecache
yum update –-skip-broken -y
reboot

# Part 2
# some variables
export ADMIN_USER="navi"
export ADMIN_PUBLIC_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC/Y6syJ5kav9k9LNl+WJFxFkSHVbASGpALeCQq/X5z4YHUs/BVLWjwZNui+gQqVpgVkguvuzgJyEFG1qmkjbc1NxFN1Giq1fFxasE8VilgxGhbNLyCJ/59tS1z6gGg1J9QPttFqHFBlwosf2p+e3xT9MpUF8V3ffTKvTB6fGnSkazCGz5pwKiRjvjR2ZRPF2bssShXQLxzKcwEi9JFmFN9sGk2lWdATZRYeTAz/PLe/j4YqtOWRc/K5ivxz5iaRypiaWn9e5J7ct/k4AsZ0WrTx+U+yzT7RR6GfASwgKcwip+HaZ+KzJBCuwdGlq+iHhspB3Ykq+QRxExMDDek/dkp5Pf9qs47HVEcoSLXHjnL91i6klnszb/AfMDr6OjPegukaOmslDwV415xO4SBwm9yjG5Vkzu1PtZcUS0XQ9Q2WVMEso2gdj7AAPntTNSMtutPxC67fCoxXmi+mCUOHQauLh3ur8qZqeTZghHI1jk5gNv/vjdNtfTvuo5TB8QL3y28lj6CRTCSgtYQAELtzE0wWrVNdGx1vOyqihWYong9GclYjveVXx/wNXwOS/IPxhkS/prjJx0P4XiJWy8cvYqP5zZKByCb4SPHczfFhoSBcIkXCgUr0QYnjwJ6WAPcQWPVlh/ZrXYxfgO6jd7RWkg2PEI0o8MA2NOIJjO728Eolw=="


# install necessary and helpful components
yum -y install net-tools nano deltarpm wget bash-completion yum-plugin-remove-with-leaves yum-utils

# Stop logging services
systemctl stop rsyslog
service auditd stop

# Remove old kernels
package-cleanup -y --oldkernels --count=1

# Clean out yum
yum clean all

# Force the logs to rotate & remove old logs we don’t need
/usr/sbin/logrotate /etc/logrotate.conf --force
rm -f /var/log/*-???????? /var/log/*.gz
rm -f /var/log/dmesg.old
rm -rf /var/log/anaconda

# Truncate the audit logs (and other logs we want to keep placeholders for)
cat /dev/null > /var/log/audit/audit.log
cat /dev/null > /var/log/wtmp
cat /dev/null > /var/log/lastlog
cat /dev/null > /var/log/grubby

# Remove the traces of the template MAC address and UUIDs
sed -i '/^\(HWADDR\|UUID\)=/d' /etc/sysconfig/network-scripts/ifcfg-e*

# enable network interface onboot
sed -i -e 's@^ONBOOT="no@ONBOOT="yes@' /etc/sysconfig/network-scripts/ifcfg-e*

# Clean /tmp out
rm -rf /tmp/*
rm -rf /var/tmp/*

# Remove the SSH host keys
rm -f /etc/ssh/*key*

# configure sshd_config to only allow Pubkey Authentication
sed -i -r 's/^#?(PermitRootLogin|PasswordAuthentication|PermitEmptyPasswords) (yes|no)/\1 no/' /etc/ssh/sshd_config
sed -i -r 's/^#?(PubkeyAuthentication) (yes|no)/\1 yes/' /etc/ssh/sshd_config

# add user 'ADMIN_USER'
adduser $ADMIN_USER

# add public SSH key
mkdir -m 700 /home/$ADMIN_USER/.ssh
chown $ADMIN_USER:$ADMIN_USER /home/$ADMIN_USER/.ssh
echo $ADMIN_PUBLIC_KEY > /home/$ADMIN_USER/.ssh/authorized_keys
chmod 600 /home/$ADMIN_USER/.ssh/authorized_keys
chown $ADMIN_USER:$ADMIN_USER /home/$ADMIN_USER/.ssh/authorized_keys

# add support for ssh-add
echo 'eval $(ssh-agent) > /dev/null' >> /home/$ADMIN_USER/.bashrc

# add user 'ADMIN_USER' to sudoers
echo "$ADMIN_USER    ALL = NOPASSWD: ALL" > /etc/sudoers.d/$ADMIN_USER
chmod 0440 /etc/sudoers.d/$ADMIN_USER

# Remove the root user’s SSH history
rm -rf ~root/.ssh/
rm -f ~root/anaconda-ks.cfg

#remove root users shell history
/bin/rm -f ~root/.bash_history
unset HISTFILE

# remove the root password
passwd -d root

# Remove the root user’s shell history
history -cw

# shutdown
sys-unconfig

