script "motd_venusville" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
  cd /tmp
  wget https://raw.githubusercontent.com/jacqueque/test_total_recon/master/motd_venusville -O /etc/motd
  for each_home in $(ls /home/)
    do cat /etc/motd > /home/$each_home/instructions.txt
  done
  EOH
end
