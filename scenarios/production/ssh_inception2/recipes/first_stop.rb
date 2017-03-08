script "message" do
  interpreter "bash"
  user "root"
  code <<-EOH
message="\\n### FIRST STOP ###\\n\\n'I'll tell you a riddle. You're waiting for a train, a train that will take you far away. You know where you hope this train will take you, but you don't know for sure.'\\n\\nYou found it. Well done. The next dream machine lies just a few addresses higher on your subnet.\\n\\n"

while read player; do
  player=$(echo -n $player)
  cd /home/$player
  echo -e $message > message
  chmod 404 message
  echo 'cat message' >> .bashrc

  echo $(edurange-get-var user $player secret_first_stop) > secret
  chown $player:$player secret
  chmod 400 secret
done </root/edurange/players
EOH
end
