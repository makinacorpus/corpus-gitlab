{% set cfg = salt['mc_project.get_configuration'](project) %}
{% set data = cfg.data %}

# To enable smtp email delivery for your GitLab instance do the following:
# 1. Rename this file to smtp_settings.rb
# 2. Edit settings inside this file
# 3. Restart GitLab instance
#
# For full list of options and their values see http://api.rubyonrails.org/classes/ActionMailer/Base.html
#

if Rails.env.production?
  Gitlab::Application.config.action_mailer.delivery_method = :smtp

  ActionMailer::Base.smtp_settings = {
    address: "{{data.smtp_address}}",
    port: {{data.smtp_port}},
{% if data.smtp_user %}
    user_name: "{{data.smtp_user}}",
{% endif %}
{% if data.smtp_password %}
    password: "{{data.smtp_password}}",
{% endif %}
    domain: "{{data.smtp_domain}}",
{% if data.smtp_password %}
    authentication: :login,
{% endif %}
{% if data.smtp_tls %}
    enable_starttls_auto: true,
{% endif %}
    openssl_verify_mode: '{{data.openssl_verify_mode}}' # See ActionMailer documentation for other possible options
  }
end
