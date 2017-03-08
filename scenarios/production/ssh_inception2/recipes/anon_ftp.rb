script "anon_ftp" do
  interpreter "bash"
  user "root"
  cwd "/tmp"

  code <<-EOH
  apt-get install vsftpd
  service vsftpd stop
  mkdir /var/ftp
  chown -hR ftp:ftp /var/ftp
  chmod 555 /var/ftp
  pass=$(edurange-get-var instance fifth_stop_password_key)
echo -e "ip: 10.0.0.17
key: ${pass}" > /var/ftp/secrets
chmod 444 /var/ftp/secrets
  echo -e "listen=YES
" > /etc/vsftpd.conf
  echo -e "local_enable=YES
" >> /etc/vsftpd.conf
  echo -e "anonymous_enable=YES
" >> /etc/vsftpd.conf
  echo -e "write_enable=NO
" >> /etc/vsftpd.conf
  echo -e "anon_root=/var/ftp
" >> /etc/vsftpd.conf
  service vsftpd start
  touch /tmp/test-file
  EOH
end
