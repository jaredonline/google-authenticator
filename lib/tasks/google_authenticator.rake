namespace :google_authenticator do

  def do_encrypt(args, already_encrypted, op_name)
    model_names = if args[:optional_model_list]
      args.extras.unshift(args[:optional_model_list])
    else
      # Adapted from https://stackoverflow.com/a/8248849/7478194
      Dir[Rails.root.join('app/models/*.rb').to_s].map { |filename| File.basename(filename, '.rb').camelize }
    end
    
    ActiveRecord::Base.transaction do
      match_op = " = #{already_encrypted ? 138 : 16}"
      model_names.each do |model_name|
        klass = model_name.constantize
        next unless klass.ancestors.include?(ActiveRecord::Base) && klass.try(:google_secrets_encrypted)
        print "#{op_name}ing model #{klass.name.inspect} (table #{klass.table_name.inspect}): "
        count = 0
        klass.where("LENGTH(#{klass.google_secret_column})#{match_op}").find_each do |record|
          yield record
          count += 1
        end
        puts "#{count} #{'secret'.pluralize(count)} #{op_name}ed"
      end
    end
  end
  
  desc 'Encrypt all secret columns (add the :encrypt_secrets options *before* running)'
  task :encrypt_secrets, [:optional_model_list] => :environment do |t, args|
    do_encrypt(args, false, 'Encrypt') { |record| record.encrypt_google_secret! }
  end

  desc 'Re-encrypt all secret columns from old_secret_key_base to secret_key_base'
  task :reencrypt_secrets, [:optional_model_list] => :environment do |t, args|
    if Rails.application.secrets.old_secret_key_base.blank?
      puts 'old_secret_key_base is not set in config/secrets.yml'
    else
      secret_encryptor = GoogleAuthenticatorRails::ActiveRecord::Helpers.get_google_secret_encryptor
      Rails.application.secrets[:secret_key_base] = Rails.application.secrets.old_secret_key_base
      Rails.application.instance_eval { @caching_key_generator = nil }
      old_secret_encryptor = GoogleAuthenticatorRails::ActiveRecord::Helpers.get_google_secret_encryptor
      do_encrypt(args, true, 'Re-encrypt') do |record|
        GoogleAuthenticatorRails.secret_encryptor = old_secret_encryptor
        plain_secret = record.google_secret_value
        GoogleAuthenticatorRails.secret_encryptor = secret_encryptor
        record.send(:change_google_secret_to!, plain_secret)
      end
    end
  end
  
  desc 'Decrypt all secret columns (remove the :encrypt_secrets options *after* running)'
  task :decrypt_secrets, [:optional_model_list] => :environment do |t, args|
    do_encrypt(args, true, 'Decrypt') { |record| record.send(:change_google_secret_to!, record.google_secret_value, false) }
  end  

end
