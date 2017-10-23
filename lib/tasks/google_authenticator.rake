namespace :google_authenticator do

  def do_encrypt(already_encrypted, op_name)
    ActiveRecord::Base.transaction do
      match_op = " #{already_encrypted ? '>' : '='} 16"
      # Adapted from https://stackoverflow.com/a/8248849/7478194
      Dir[Rails.root.join('app/models/*.rb').to_s].each do |filename|
        klass = File.basename(filename, '.rb').camelize.constantize
        next unless klass.ancestors.include?(ActiveRecord::Base) && klass.try(:google_secret_encrypted)
        puts "#{op_name} model #{klass.name.inspect} (table #{klass.table_name.inspect})"
        klass.where("LENGTH(#{klass.google_secret_column})#{match_op}").find_each do |record|
          yield record
        end
      end
    end
  end
  
  desc 'Encrypt all secret columns (add the :encrypt_secret options *before* running)'
  task encrypt_secrets: :environment do
    do_encrypt(false, 'Encrypting') { |record| record.encrypt_google_secret! }
  end

  desc 'Re-encrypt all secret columns from old_secret_key_base to secret_key_base'
  task reencrypt_secrets: :environment do
    if Rails.application.secrets.old_secret_key_base.blank?
      puts 'old_secret_key_base is not set in config/secrets.yml'
    else
      secret_encryptor = GoogleAuthenticatorRails::ActiveRecord::Helpers.get_google_secret_encryptor
      Rails.application.secrets[:secret_key_base] = Rails.application.secrets.old_secret_key_base
      Rails.application.instance_eval { @caching_key_generator = nil }
      old_secret_encryptor = GoogleAuthenticatorRails::ActiveRecord::Helpers.get_google_secret_encryptor
      do_encrypt(true, 'Re-encrypting') do |record|
        GoogleAuthenticatorRails.secret_encryptor = old_secret_encryptor
        plain_secret = record.send(:google_secret_value_plain)
        GoogleAuthenticatorRails.secret_encryptor = secret_encryptor
        record.send(:change_google_secret_to!, plain_secret)
      end
    end
  end
  
  desc 'Decrypt all secret columns (remove the :encrypt_secret options *after* running)'
  task decrypt_secrets: :environment do
    do_encrypt(true, 'Decrypting') { |record| record.send(:change_google_secret_to!, record.send(:google_secret_value_plain), false) }
  end  

end
