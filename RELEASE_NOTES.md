# Release Notes

## 1. Upgrade notes

As usual, we recommend that you have a full backup, of the database, application code and static files.

To update, follow these steps:

### 1.1. Update your ruby version

If you're using rbenv, this is done with the following commands:

```console
rbenv install 3.x.x
rbenv local 3.x.x
```

You may need to change your `.ruby-version` file too.

If not, you need to adapt it to your environment, for instance by changing the decidim docker image to use ruby:3.x.x.

### 1.2. Update your Gemfile

```ruby
gem "decidim", github: "decidim/decidim"
gem "decidim-dev", github: "decidim/decidim"
```

### 1.3. Run these commands

```console
bundle update decidim
bin/rails decidim:upgrade
bin/rails db:migrate
```

### 1.4. Follow the steps and commands detailed in these notes

## 2. General notes

### 2.1. Hiding comments of moderated resources

We have noticed that when a resource (ex: Proposal, Meeting) is being moderated, the associated comments are left visible in the search. We have added a task that would allow you to automatically remove from search any comment belonging to moderated content:

```bash
bin/rails decidim:upgrade:clean:hidden_resources
```

You can read more about this change on PR [#13554](https://github.com/decidim/decidim/pull/13554).

### 2.2. User Groups removal

As part of our efforts to simplify the experience for organizations, the "User Groups" feature has been deprecated. All previously existing User Groups has been converted into regular participants able to sign in providing the email and a password. The users with access to the email associated with the User Group will be able to set a password.

There are some tasks to notify users affected by the changes, transfer authorships and remove deprecated references to groups. All of them can be executed in a main task:

```bash
bin/rails decidim:upgrade:user_groups:remove
```

The tasks can also be executed one by one:

* An email will be sent to the email address associated with the User Group, informing them of the deprecation of User Groups and instructing them to define a password for the newly converted profile. For this run:

```bash
bin/rails decidim:upgrade:user_groups:send_reset_password_instructions
```

* To notify group members and admins associated with the User Group with an email explaining the changes and how to access the shared profile run:

```bash
bin/rails decidim:upgrade:user_groups:send_user_group_changes_notification_to_members
```

* To migrate the authorships and coauthorships of the old groups and assign to the new regular users:

```bash
bin/rails decidim:upgrade:user_groups:transfer_user_groups_authorships
```

* To avoid exceptions accessing to the activities log in the admin panel displaying activities associated with user groups:

```bash
bin/rails decidim:upgrade:user_groups:fix_user_groups_action_logs
```

* To avoid exceptions trying to display notifications associated with deprecated groups events:

```bash
bin/rails decidim:upgrade:user_groups:remove_groups_notifications
```

You can read more about this change on PR [#14130](https://github.com/decidim/decidim/pull/14130).

### 2.3. Initiatives digital signature process change

The application changes the configuration of initiatives signature in initiatives types to allow developers to define the process in a flexible way. This is achieved by introducing signature workflows [#13729](https://github.com/decidim/decidim/pull/13729).

To define a signature workflow create an initializer in your application and register it:

For example, in `config/initializers/decidim_initiatives.rb`:

```ruby
Decidim::Initiatives::Signatures.register_workflow(:dummy_signature_handler) do |workflow|
  workflow.form = "DummySignatureHandler"
  workflow.authorization_handler_form = "DummyAuthorizationHandler"
  workflow.action_authorizer = "DummySignatureHandler::DummySignatureActionAuthorizer"
  workflow.promote_authorization_validation_errors = true
  workflow.sms_verification = true
  workflow.sms_mobile_phone_validator = "DummySmsMobilePhoneValidator"
end

Decidim::Initiatives::Signatures.register_workflow(:dummy_signature_with_sms_handler) do |workflow|
  workflow.form = "Decidim::Initiatives::SignatureHandler"
  workflow.sms_verification = true
end

Decidim::Initiatives::Signatures.register_workflow(:dummy_signature_with_personal_data_handler) do |workflow|
  workflow.form = "DummySignatureHandler"
  workflow.authorization_handler_form = "DummyAuthorizationHandler"
  workflow.action_authorizer = "DummySignatureHandler::DummySignatureActionAuthorizer"
  workflow.promote_authorization_validation_errors = true
  workflow.save_authorizations = false
end

Decidim::Initiatives::Signatures.register_workflow(:legacy_signature_handler) do |workflow|
  workflow.form = "Decidim::Initiatives::LegacySignatureHandler"
  workflow.authorization_handler_form = "DummyAuthorizationHandler"
  workflow.save_authorizations = false
  workflow.sms_verification = true
end
```

All the attributes of a workflow are optional except the registered name with which the workflow is registered. A flow without attributes uses default values that generate a direct signature process without steps.

Signature workflows can be defined as ephemeral, in which case users can sign initiatives without prior registration. For a workflow of this type to work correctly, an authorization handler form must be defined in `authorization_handler_form` and authorizations saving must not be disabled using the `save_authorizations` setting, in order to ensure that user verifications are saved based on the personal data they provide.

To migrate old signature configurations review the One time actions section

For more information about the definition of a signature workflow read the documentation of `Decidim::Initiatives::SignatureWorkflowManifest`

### 2.4. [[TITLE OF THE ACTION]]

You can read more about this change on PR [#xxxx](https://github.com/decidim/decidim/pull/xxx).

## 3. One time actions

These are one time actions that need to be done after the code is updated in the production database.

### 3.1. Changes in Static maps configuration when using HERE.com

As of [#14180](https://github.com/decidim/decidim/pull/14180) we are migrating to here.com api V3, as V1 does not work anymore. In case your application uses Here.com as static map tile provider, you will need to change your `config/initializers/decidim.rb` to use the new url `https://image.maps.hereapi.com/mia/v3/base/mc/overlay`:

```ruby
  static_url = "https://image.maps.ls.hereapi.com/mia/1.6/mapview" if static_provider == "here" && static_url.blank?
```

to

```ruby
  static_url = "https://image.maps.hereapi.com/mia/v3/base/mc/overlay" if static_provider == "here" && static_url.blank?
```

You can read more about this change on PR [#14180](https://github.com/decidim/decidim/pull/14180).

### 3.2. Migrate signature configuration of initiatives types

If there is any type of initiative with online signature enabled, you will have to reproduce the configuration by defining signature workflows. For direct signing is not necessary to define one or define an empty workflow.

Use the following definition scheme and adapt the values as indicated in the comments:

```ruby
Decidim::Initiatives::Signatures.register_workflow(:legacy_signature_handler) do |workflow|
  # Enable this form to enable the same user data collection and store the same
  # fields in the vote metadata when the "Collect participant personal data on
  # signature" were checked
  workflow.form = "Decidim::Initiatives::LegacySignatureHandler"

  # Change this form and use the same handler selected in the "Authorization to
  # verify document number on signatures" field
  workflow.authorization_handler_form = "DummyAuthorizationHandler"

  # This setting prevents the automatic creation of authorizations as in the
  # old feature. You can remove this setting if the workflow does not use an
  # authorization handler form. The default value is true.
  workflow.save_authorizations = false

  # Set this setting to false or remove to skip SMS verification step
  workflow.sms_verification = true
end
```

Register a workflow for each different signature configuration and select them in the initiative type admin "Signature workflow" field

You can read more about this change on PR [#13729](https://github.com/decidim/decidim/pull/13729).

### 3.3. [[TITLE OF THE ACTION]]

You can read more about this change on PR [#XXXX](https://github.com/decidim/decidim/pull/XXXX).

## 4. Scheduled tasks

Implementers need to configure these changes it in your scheduler task system in the production server. We give the examples
with `crontab`, although alternatively you could use `whenever` gem or the scheduled jobs of your hosting provider.

### 4.1. [[TITLE OF THE TASK]]

```bash
4 0 * * * cd /home/user/decidim_application && RAILS_ENV=production bundle exec rails decidim:TASK
```

You can read more about this change on PR [#XXXX](https://github.com/decidim/decidim/pull/XXXX).

## 5. Changes in APIs

### 5.1. [[TITLE OF THE CHANGE]]

In order to [[REASONING (e.g. improve the maintenance of the code base)]] we have changed...

If you have used code as such:

```ruby
# Explain the usage of the API as it was in the previous version
result = 1 + 1 if before
```

```ruby
# Explain the usage of the API as it is in the new version
result = 1 + 1 if after
```

### 5.2. Add force_api_authentication configuration options

There are times that we need to let only authenticated users to use the API. This configuration option filters out unauthenticated users from accessing the api endpoint. You need to add `DECIDIM_API_FORCE_API_AUTHENTICATION` to your environment variables if you want to enable this feature.
