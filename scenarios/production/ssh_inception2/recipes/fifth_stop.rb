script "fifth_stop_script" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
 code <<-EOH
message="\\\n\\n### FIFTH STOP ###\\n\\n'The ecstasy that blooms in synapses is Paprika-brand milk fat! 5% is the norm. The safety net of the ocean is nonlinear, even with what crabs dream of! Lets go!\\n\\nDecode the file 'betcha_cant_read_me' to find your way to the ultimate challenge... SATAN'S PALACE\\n\\n"

while read player; do
  player=$(echo -n $player)
  cd /home/$player

  echo -e $message > message
  chown $player:$player message
  chmod 400 message
  echo 'cat message' >> .bashrc

  password=$(edurange-get-var user $player fifth_stop_password)
  echo -e "${password}\\n${password}" | passwd $player

  password=$(edurange-get-var user $player satans_palace_password)
  echo "You found me. Good job. The next challenge will not be so easy. You will find Satans Palace on the host with a certain open port. The most evil open port. SSH to that port with the password '${password}'. The final treasure awaits..." | base64 > betcha_cant_read_me

  chown $player:$player betcha_cant_read_me
  chmod 400 betcha_cant_read_me

  echo $(edurange-get-var user $player secret_fifth_stop) > secret
  chown $player:$player secret
  chmod 400 secret
done </root/edurange/players
  EOH
end
