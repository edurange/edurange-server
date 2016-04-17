
if Rails.configuration.x.provider == 'aws'

  # test for correct environment variables
  begin
    raise 'err' if not ENV['AWS_ACCESS_KEY_ID']
    raise 'err' if not ENV['AWS_SECRET_ACCESS_KEY']
    raise 'err' if not ENV['AWS_REGION']
    AWS::EC2.new.vpcs.count
  rescue AWS::EC2::Errors::AuthFailure, Exception
    puts "\nOne or more of your Aws environment variables are invalid:\n\n"
    puts "AWS_ACCESS_KEY_ID=" + ENV['AWS_ACCESS_KEY_ID']
    puts "AWS_SECRET_ACCESS_KEY" + ENV['AWS_SECRET_ACCESS_KEY']
    puts "AWS_REGION=" + ENV['AWS_REGION']
    puts ""
    raise 'AWS Config Error'
  rescue => e
    puts "\nGet the following from your EDURange Aws admin and place them in your environment variables:\n\n"
    puts "AWS_SECRET_ACCESS_KEY\nAWS_REGION\nAWS_ACCESS_KEY_ID\n\n"
    raise 'AWS Config Error'
  end

  # get iam user name and set some aws configs
  begin
    AWS::IAM::Client.new.create_access_key
  rescue => e
    Rails.configuration.x.aws['iam_user_name'] = /user\/.* is/.match(e.message).to_s.gsub("user\/", "").gsub(" is", "")
  end
  Rails.configuration.x.aws['s3_bucket_name'] = Rails.configuration.x.aws['iam_user_name']
  Rails.configuration.x.aws['ec2_key_pair_name'] = "#{Rails.configuration.x.aws['iam_user_name']}-#{Rails.configuration.x.aws['region']}"

  # create keypair if it doesn't already exist
  aws_key_pair_path = "#{Rails.root}/keys/#{Rails.configuration.x.aws['ec2_key_pair_name']}"
  FileUtils.mkdir("#{Rails.root}/keys") if not File.exists?("#{Rails.root}/keys")
  if not File.exists?(aws_key_pair_path)
    begin
      aws_key_pair = AWS::EC2::Client.new.create_key_pair(key_name: Rails.configuration.x.aws['ec2_key_pair_name'])
      File.open(aws_key_pair_path, "w") { |f| f.write(aws_key_pair[:key_material]) }
      FileUtils.chmod(0400, aws_key_pair_path)
    rescue
    end
  end

end

