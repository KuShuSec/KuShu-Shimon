@secure()
param apis_isdfwriter_la_path string

@secure()
param backends_isdf_be_pool_url string

@secure()
param backends_isdf_be_pool_protocol string

@secure()
param properties_68acad0fbb1eff4b373a9fc6_value string

@secure()
param subscriptions_68ac83b840fa460066070001_displayName string

@secure()
param subscriptions_68ac83b840fa460066070002_displayName string

@secure()
param users_1_lastName string
param service_isdf_apim_01_name string = 'isdf-apim-01'

resource service_isdf_apim_01_name_resource 'Microsoft.ApiManagement/service@2024-06-01-preview' = {
  name: service_isdf_apim_01_name
  location: 'North Europe'
  sku: {
    name: 'Developer'
    capacity: 1
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: 'NAME@DOMAIN'
    publisherName: 'PUBLISHER'
    notificationSenderEmail: 'apimgmt-noreply@mail.windowsazure.com'
    hostnameConfigurations: [
      {
        type: 'Proxy'
        hostName: '${service_isdf_apim_01_name}.azure-api.net'
        negotiateClientCertificate: true
        defaultSslBinding: true
        certificateSource: 'BuiltIn'
      }
    ]
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Ssl30': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TripleDes168': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Ssl30': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Protocols.Server.Http2': 'False'
    }
    virtualNetworkType: 'None'
    certificates: [
      {
        storeName: 'Root'
        certificate: {
          expiry: 'ROOT_EXPIRY'
          thumbprint: 'ROOT_THUMBPRINT'
          subject: 'ROOT_SUBJECT'
        }
      }
      {
        storeName: 'CertificateAuthority'
        certificate: {
          expiry: 'ISS_EXPIRY'
          thumbprint: 'ISS_THUMBPRINT'
          subject: 'ISS_SUBJECT'
        }
      }
    ]
    disableGateway: false
    natGatewayState: 'Unsupported'
    apiVersionConstraint: {}
    publicNetworkAccess: 'Enabled'
    legacyPortalStatus: 'Disabled'
    developerPortalStatus: 'Enabled'
    releaseChannel: 'Default'
  }
}

resource service_isdf_apim_01_name_echo_api 'Microsoft.ApiManagement/service/apis@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'echo-api'
  properties: {
    displayName: 'Echo API'
    apiRevision: '1'
    subscriptionRequired: true
    serviceUrl: 'https://echo.playground.azure-api.net/api'
    path: 'echo'
    protocols: [
      'https'
    ]
    authenticationSettings: {
      oAuth2AuthenticationSettings: []
      openidAuthenticationSettings: []
    }
    subscriptionKeyParameterNames: {
      header: 'Ocp-Apim-Subscription-Key'
      query: 'subscription-key'
    }
    isCurrent: true
  }
}

resource service_isdf_apim_01_name_isdfwriter_la 'Microsoft.ApiManagement/service/apis@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'isdfwriter-la'
  properties: {
    displayName: 'isdfwriter-la'
    apiRevision: '1'
    description: 'Azure Logic App.'
    subscriptionRequired: false
    serviceUrl: 'https://APIM_BASE_URL'
    protocols: [
      'https'
    ]
    authenticationSettings: {
      oAuth2AuthenticationSettings: []
      openidAuthenticationSettings: []
    }
    subscriptionKeyParameterNames: {
      header: 'Ocp-Apim-Subscription-Key'
      query: 'subscription-key'
    }
    isCurrent: true
    path: apis_isdfwriter_la_path
  }
}

resource service_isdf_apim_01_name_la_isdf_direct 'Microsoft.ApiManagement/service/backends@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'la-isdf-direct'
  properties: {
    type: 'Single'
    url: 'https://LOGIC_APP_BASE_URL'
    protocol: 'http'
    credentials: {
      query: {}
      header: {}
    }
    tls: {
      validateCertificateChain: true
      validateCertificateName: false
    }
  }
}

resource service_isdf_apim_01_name_administrators 'Microsoft.ApiManagement/service/groups@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'administrators'
  properties: {
    displayName: 'Administrators'
    description: 'Administrators is a built-in group containing the admin email account provided at the time of service creation. Its membership is managed by the system.'
    type: 'system'
  }
}

resource service_isdf_apim_01_name_developers 'Microsoft.ApiManagement/service/groups@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'developers'
  properties: {
    displayName: 'Developers'
    description: 'Developers is a built-in group. Its membership is managed by the system. Signed-in users fall into this group.'
    type: 'system'
  }
}

resource service_isdf_apim_01_name_guests 'Microsoft.ApiManagement/service/groups@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'guests'
  properties: {
    displayName: 'Guests'
    description: 'Guests is a built-in group. Its membership is managed by the system. Unauthenticated users visiting the developer portal fall into this group.'
    type: 'system'
  }
}

resource service_isdf_apim_01_name_azuremonitor 'Microsoft.ApiManagement/service/loggers@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'azuremonitor'
  properties: {
    loggerType: 'azureMonitor'
    isBuffered: true
  }
}

resource service_isdf_apim_01_name_68acad0fbb1eff4b373a9fc6 'Microsoft.ApiManagement/service/namedValues@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: '68acad0fbb1eff4b373a9fc6'
  properties: {
    displayName: 'isdfwriter-la_When_a_HTTP_request_is_received-invoke_68acad0fbb1eff4b373a9fc6'
    tags: []
    secret: true
  }
}

resource service_isdf_apim_01_name_AccountClosedPublisher 'Microsoft.ApiManagement/service/notifications@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'AccountClosedPublisher'
}

resource service_isdf_apim_01_name_BCC 'Microsoft.ApiManagement/service/notifications@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'BCC'
}

resource service_isdf_apim_01_name_NewApplicationNotificationMessage 'Microsoft.ApiManagement/service/notifications@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'NewApplicationNotificationMessage'
}

resource service_isdf_apim_01_name_NewIssuePublisherNotificationMessage 'Microsoft.ApiManagement/service/notifications@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'NewIssuePublisherNotificationMessage'
}

resource service_isdf_apim_01_name_PurchasePublisherNotificationMessage 'Microsoft.ApiManagement/service/notifications@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'PurchasePublisherNotificationMessage'
}

resource service_isdf_apim_01_name_QuotaLimitApproachingPublisherNotificationMessage 'Microsoft.ApiManagement/service/notifications@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'QuotaLimitApproachingPublisherNotificationMessage'
}

resource service_isdf_apim_01_name_RequestPublisherNotificationMessage 'Microsoft.ApiManagement/service/notifications@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'RequestPublisherNotificationMessage'
}

resource service_isdf_apim_01_name_policy 'Microsoft.ApiManagement/service/policies@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'policy'
  properties: {
    value: '<!--\r\n    IMPORTANT:\r\n    - Policy elements can appear only within the <inbound>, <outbound>, <backend> section elements.\r\n    - Only the <forward-request> policy element can appear within the <backend> section element.\r\n    - To apply a policy to the incoming request (before it is forwarded to the backend service), place a corresponding policy element within the <inbound> section element.\r\n    - To apply a policy to the outgoing response (before it is sent back to the caller), place a corresponding policy element within the <outbound> section element.\r\n    - To add a policy position the cursor at the desired insertion point and click on the round button associated with the policy.\r\n    - To remove a policy, delete the corresponding policy statement from the policy document.\r\n    - Policies are applied in the order of their appearance, from the top down.\r\n-->\r\n<policies>\r\n  <inbound />\r\n  <backend>\r\n    <forward-request />\r\n  </backend>\r\n  <outbound />\r\n</policies>'
    format: 'xml'
  }
}

resource service_isdf_apim_01_name_default 'Microsoft.ApiManagement/service/portalconfigs@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'default'
  properties: {
    enableBasicAuth: true
    signin: {
      require: false
    }
    signup: {
      termsOfService: {
        requireConsent: false
      }
    }
    delegation: {
      delegateRegistration: false
      delegateSubscription: false
    }
    cors: {
      allowedOrigins: []
    }
    csp: {
      mode: 'disabled'
      reportUri: []
      allowedSources: []
    }
  }
}

resource service_isdf_apim_01_name_delegation 'Microsoft.ApiManagement/service/portalsettings@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'delegation'
  properties: {
    subscriptions: {
      enabled: false
    }
    userRegistration: {
      enabled: false
    }
  }
}

resource service_isdf_apim_01_name_signin 'Microsoft.ApiManagement/service/portalsettings@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'signin'
  properties: {
    enabled: false
  }
}

resource service_isdf_apim_01_name_signup 'Microsoft.ApiManagement/service/portalsettings@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'signup'
  properties: {
    enabled: true
    termsOfService: {
      enabled: false
      consentRequired: false
    }
  }
}

resource service_isdf_apim_01_name_starter 'Microsoft.ApiManagement/service/products@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'starter'
  properties: {
    displayName: 'Starter'
    description: 'Subscribers will be able to run 5 calls/minute up to a maximum of 100 calls/week.'
    subscriptionRequired: true
    approvalRequired: false
    subscriptionsLimit: 1
    state: 'published'
  }
}

resource service_isdf_apim_01_name_unlimited 'Microsoft.ApiManagement/service/products@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'unlimited'
  properties: {
    displayName: 'Unlimited'
    description: 'Subscribers have completely unlimited access to the API. Administrator approval is required.'
    subscriptionRequired: true
    approvalRequired: true
    subscriptionsLimit: 1
    state: 'published'
  }
}

resource Microsoft_ApiManagement_service_properties_service_isdf_apim_01_name_68acad0fbb1eff4b373a9fc6 'Microsoft.ApiManagement/service/properties@2019-01-01' = {
  parent: service_isdf_apim_01_name_resource
  name: '68acad0fbb1eff4b373a9fc6'
  properties: {
    displayName: 'isdfwriter-la_When_a_HTTP_request_is_received-invoke_68acad0fbb1eff4b373a9fc6'
    tags: []
    secret: true
    value: properties_68acad0fbb1eff4b373a9fc6_value
  }
}

resource service_isdf_apim_01_name_master 'Microsoft.ApiManagement/service/subscriptions@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'master'
  properties: {
    scope: '${service_isdf_apim_01_name_resource.id}/'
    displayName: 'Built-in all-access subscription'
    state: 'active'
    allowTracing: false
  }
}

resource service_isdf_apim_01_name_AccountClosedDeveloper 'Microsoft.ApiManagement/service/templates@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'AccountClosedDeveloper'
  properties: {
    subject: 'Thank you for using the $OrganizationName API!'
    body: '<!DOCTYPE html >\r\n<html>\r\n  <head />\r\n  <body>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">Dear $DevFirstName $DevLastName,</p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">\r\n          On behalf of $OrganizationName and our customers we thank you for giving us a try. Your $OrganizationName API account is now closed.\r\n        </p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">Thank you,</p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">Your $OrganizationName Team</p>\r\n    <a href="$DevPortalUrl">$DevPortalUrl</a>\r\n    <p />\r\n  </body>\r\n</html>'
    title: 'Developer farewell letter'
    description: 'Developers receive this farewell email after they close their account.'
    parameters: [
      {
        name: 'DevFirstName'
        title: 'Developer first name'
      }
      {
        name: 'DevLastName'
        title: 'Developer last name'
      }
      {
        name: 'OrganizationName'
        title: 'Organization name'
      }
      {
        name: 'DevPortalUrl'
        title: 'Developer portal URL'
      }
    ]
  }
}

resource service_isdf_apim_01_name_ApplicationApprovedNotificationMessage 'Microsoft.ApiManagement/service/templates@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'ApplicationApprovedNotificationMessage'
  properties: {
    subject: 'Your application $AppName is published in the application gallery'
    body: '<!DOCTYPE html >\r\n<html>\r\n  <head />\r\n  <body>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">Dear $DevFirstName $DevLastName,</p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">\r\n          We are happy to let you know that your request to publish the $AppName application in the application gallery has been approved. Your application has been published and can be viewed <a href="http://$DevPortalUrl/Applications/Details/$AppId">here</a>.\r\n        </p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">Best,</p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">The $OrganizationName API Team</p>\r\n  </body>\r\n</html>'
    title: 'Application gallery submission approved (deprecated)'
    description: 'Developers who submitted their application for publication in the application gallery on the developer portal receive this email after their submission is approved.'
    parameters: [
      {
        name: 'AppId'
        title: 'Application id'
      }
      {
        name: 'AppName'
        title: 'Application name'
      }
      {
        name: 'DevFirstName'
        title: 'Developer first name'
      }
      {
        name: 'DevLastName'
        title: 'Developer last name'
      }
      {
        name: 'OrganizationName'
        title: 'Organization name'
      }
      {
        name: 'DevPortalUrl'
        title: 'Developer portal URL'
      }
    ]
  }
}

resource service_isdf_apim_01_name_ConfirmSignUpIdentityDefault 'Microsoft.ApiManagement/service/templates@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'ConfirmSignUpIdentityDefault'
  properties: {
    subject: 'Please confirm your new $OrganizationName API account'
    body: '<!DOCTYPE html >\r\n<html>\r\n  <head>\r\n    <meta charset="UTF-8" />\r\n    <title>Letter</title>\r\n  </head>\r\n  <body>\r\n    <table width="100%">\r\n      <tr>\r\n        <td>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">Dear $DevFirstName $DevLastName,</p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'"></p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">Thank you for joining the $OrganizationName API program! We host a growing number of cool APIs and strive to provide an awesome experience for API developers.</p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">First order of business is to activate your account and get you going. To that end, please click on the following link:</p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">\r\n            <a id="confirmUrl" href="$ConfirmUrl" style="text-decoration:none">\r\n              <strong>$ConfirmUrl</strong>\r\n            </a>\r\n          </p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">If clicking the link does not work, please copy-and-paste or re-type it into your browser\'s address bar and hit "Enter".</p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">Thank you,</p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">$OrganizationName API Team</p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">\r\n            <a href="$DevPortalUrl">$DevPortalUrl</a>\r\n          </p>\r\n        </td>\r\n      </tr>\r\n    </table>\r\n  </body>\r\n</html>'
    title: 'New developer account confirmation'
    description: 'Developers receive this email to confirm their e-mail address after they sign up for a new account.'
    parameters: [
      {
        name: 'DevFirstName'
        title: 'Developer first name'
      }
      {
        name: 'DevLastName'
        title: 'Developer last name'
      }
      {
        name: 'OrganizationName'
        title: 'Organization name'
      }
      {
        name: 'DevPortalUrl'
        title: 'Developer portal URL'
      }
      {
        name: 'ConfirmUrl'
        title: 'Developer activation URL'
      }
      {
        name: 'DevPortalHost'
        title: 'Developer portal hostname'
      }
      {
        name: 'ConfirmQuery'
        title: 'Query string part of the activation URL'
      }
    ]
  }
}

resource service_isdf_apim_01_name_EmailChangeIdentityDefault 'Microsoft.ApiManagement/service/templates@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'EmailChangeIdentityDefault'
  properties: {
    subject: 'Please confirm the new email associated with your $OrganizationName API account'
    body: '<!DOCTYPE html >\r\n<html>\r\n  <head>\r\n    <meta charset="UTF-8" />\r\n    <title>Letter</title>\r\n  </head>\r\n  <body>\r\n    <table width="100%">\r\n      <tr>\r\n        <td>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">Dear $DevFirstName $DevLastName,</p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'"></p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">You are receiving this email because you made a change to the email address on your $OrganizationName API account.</p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">Please click on the following link to confirm the change:</p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">\r\n            <a id="confirmUrl" href="$ConfirmUrl" style="text-decoration:none">\r\n              <strong>$ConfirmUrl</strong>\r\n            </a>\r\n          </p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">If clicking the link does not work, please copy-and-paste or re-type it into your browser\'s address bar and hit "Enter".</p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">Thank you,</p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">$OrganizationName API Team</p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">\r\n            <a href="$DevPortalUrl">$DevPortalUrl</a>\r\n          </p>\r\n        </td>\r\n      </tr>\r\n    </table>\r\n  </body>\r\n</html>'
    title: 'Email change confirmation'
    description: 'Developers receive this email to confirm a new e-mail address after they change their existing one associated with their account.'
    parameters: [
      {
        name: 'DevFirstName'
        title: 'Developer first name'
      }
      {
        name: 'DevLastName'
        title: 'Developer last name'
      }
      {
        name: 'OrganizationName'
        title: 'Organization name'
      }
      {
        name: 'DevPortalUrl'
        title: 'Developer portal URL'
      }
      {
        name: 'ConfirmUrl'
        title: 'Developer confirmation URL'
      }
      {
        name: 'DevPortalHost'
        title: 'Developer portal hostname'
      }
      {
        name: 'ConfirmQuery'
        title: 'Query string part of the confirmation URL'
      }
    ]
  }
}

resource service_isdf_apim_01_name_InviteUserNotificationMessage 'Microsoft.ApiManagement/service/templates@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'InviteUserNotificationMessage'
  properties: {
    subject: 'You are invited to join the $OrganizationName developer network'
    body: '<!DOCTYPE html >\r\n<html>\r\n  <head />\r\n  <body>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">Dear $DevFirstName $DevLastName,</p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">\r\n          Your account has been created. Please follow the link below to visit the $OrganizationName developer portal and claim it:\r\n        </p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">\r\n      <a href="$ConfirmUrl">$ConfirmUrl</a>\r\n    </p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">Best,</p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">The $OrganizationName API Team</p>\r\n  </body>\r\n</html>'
    title: 'Invite user'
    description: 'An e-mail invitation to create an account, sent on request by API publishers.'
    parameters: [
      {
        name: 'OrganizationName'
        title: 'Organization name'
      }
      {
        name: 'DevFirstName'
        title: 'Developer first name'
      }
      {
        name: 'DevLastName'
        title: 'Developer last name'
      }
      {
        name: 'ConfirmUrl'
        title: 'Confirmation link'
      }
      {
        name: 'DevPortalHost'
        title: 'Developer portal hostname'
      }
      {
        name: 'ConfirmQuery'
        title: 'Query string part of the confirmation link'
      }
    ]
  }
}

resource service_isdf_apim_01_name_NewCommentNotificationMessage 'Microsoft.ApiManagement/service/templates@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'NewCommentNotificationMessage'
  properties: {
    subject: '$IssueName issue has a new comment'
    body: '<!DOCTYPE html >\r\n<html>\r\n  <head />\r\n  <body>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">Dear $DevFirstName $DevLastName,</p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">This is a brief note to let you know that $CommenterFirstName $CommenterLastName made the following comment on the issue $IssueName you created:</p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">$CommentText</p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">\r\n          To view the issue on the developer portal click <a href="http://$DevPortalUrl/issues/$IssueId">here</a>.\r\n        </p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">Best,</p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">The $OrganizationName API Team</p>\r\n  </body>\r\n</html>'
    title: 'New comment added to an issue (deprecated)'
    description: 'Developers receive this email when someone comments on the issue they created on the Issues page of the developer portal.'
    parameters: [
      {
        name: 'DevFirstName'
        title: 'Developer first name'
      }
      {
        name: 'DevLastName'
        title: 'Developer last name'
      }
      {
        name: 'CommenterFirstName'
        title: 'Commenter first name'
      }
      {
        name: 'CommenterLastName'
        title: 'Commenter last name'
      }
      {
        name: 'IssueId'
        title: 'Issue id'
      }
      {
        name: 'IssueName'
        title: 'Issue name'
      }
      {
        name: 'CommentText'
        title: 'Comment text'
      }
      {
        name: 'OrganizationName'
        title: 'Organization name'
      }
      {
        name: 'DevPortalUrl'
        title: 'Developer portal URL'
      }
    ]
  }
}

resource service_isdf_apim_01_name_NewDeveloperNotificationMessage 'Microsoft.ApiManagement/service/templates@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'NewDeveloperNotificationMessage'
  properties: {
    subject: 'Welcome to the $OrganizationName API!'
    body: '<!DOCTYPE html >\r\n<html>\r\n  <head>\r\n    <meta charset="UTF-8" />\r\n    <title>Letter</title>\r\n  </head>\r\n  <body>\r\n    <h1 style="color:#000505;font-size:18pt;font-family:\'Segoe UI\'">\r\n          Welcome to <span style="color:#003363">$OrganizationName API!</span></h1>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">Dear $DevFirstName $DevLastName,</p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">Your $OrganizationName API program registration is completed and we are thrilled to have you as a customer. Here are a few important bits of information for your reference:</p>\r\n    <table width="100%" style="margin:20px 0">\r\n      <tr>\r\n            #if ($IdentityProvider == "Basic")\r\n            <td width="50%" style="height:40px;vertical-align:top;font-family:\'Segoe UI\';font-size:12pt">\r\n              Please use the following <strong>username</strong> when signing into any of the \${OrganizationName}-hosted developer portals:\r\n            </td><td style="vertical-align:top;font-family:\'Segoe UI\';font-size:12pt"><strong>$DevUsername</strong></td>\r\n            #else\r\n            <td width="50%" style="height:40px;vertical-align:top;font-family:\'Segoe UI\';font-size:12pt">\r\n              Please use the following <strong>$IdentityProvider account</strong> when signing into any of the \${OrganizationName}-hosted developer portals:\r\n            </td><td style="vertical-align:top;font-family:\'Segoe UI\';font-size:12pt"><strong>$DevUsername</strong></td>            \r\n            #end\r\n          </tr>\r\n      <tr>\r\n        <td style="height:40px;vertical-align:top;font-family:\'Segoe UI\';font-size:12pt">\r\n              We will direct all communications to the following <strong>email address</strong>:\r\n            </td>\r\n        <td style="vertical-align:top;font-family:\'Segoe UI\';font-size:12pt">\r\n          <a href="mailto:$DevEmail" style="text-decoration:none">\r\n            <strong>$DevEmail</strong>\r\n          </a>\r\n        </td>\r\n      </tr>\r\n    </table>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">Best of luck in your API pursuits!</p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">$OrganizationName API Team</p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">\r\n      <a href="http://$DevPortalUrl">$DevPortalUrl</a>\r\n    </p>\r\n  </body>\r\n</html>'
    title: 'Developer welcome letter'
    description: 'Developers receive this “welcome” email after they confirm their new account.'
    parameters: [
      {
        name: 'DevFirstName'
        title: 'Developer first name'
      }
      {
        name: 'DevLastName'
        title: 'Developer last name'
      }
      {
        name: 'DevUsername'
        title: 'Developer user name'
      }
      {
        name: 'DevEmail'
        title: 'Developer email'
      }
      {
        name: 'OrganizationName'
        title: 'Organization name'
      }
      {
        name: 'DevPortalUrl'
        title: 'Developer portal URL'
      }
      {
        name: 'IdentityProvider'
        title: 'Identity Provider selected by Organization'
      }
    ]
  }
}

resource service_isdf_apim_01_name_NewIssueNotificationMessage 'Microsoft.ApiManagement/service/templates@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'NewIssueNotificationMessage'
  properties: {
    subject: 'Your request $IssueName was received'
    body: '<!DOCTYPE html >\r\n<html>\r\n  <head />\r\n  <body>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">Dear $DevFirstName $DevLastName,</p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">Thank you for contacting us. Our API team will review your issue and get back to you soon.</p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">\r\n          Click this <a href="http://$DevPortalUrl/issues/$IssueId">link</a> to view or edit your request.\r\n        </p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">Best,</p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">The $OrganizationName API Team</p>\r\n  </body>\r\n</html>'
    title: 'New issue received (deprecated)'
    description: 'This email is sent to developers after they create a new topic on the Issues page of the developer portal.'
    parameters: [
      {
        name: 'DevFirstName'
        title: 'Developer first name'
      }
      {
        name: 'DevLastName'
        title: 'Developer last name'
      }
      {
        name: 'IssueId'
        title: 'Issue id'
      }
      {
        name: 'IssueName'
        title: 'Issue name'
      }
      {
        name: 'OrganizationName'
        title: 'Organization name'
      }
      {
        name: 'DevPortalUrl'
        title: 'Developer portal URL'
      }
    ]
  }
}

resource service_isdf_apim_01_name_PasswordResetByAdminNotificationMessage 'Microsoft.ApiManagement/service/templates@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'PasswordResetByAdminNotificationMessage'
  properties: {
    subject: 'Your password was reset'
    body: '<!DOCTYPE html >\r\n<html>\r\n  <head />\r\n  <body>\r\n    <table width="100%">\r\n      <tr>\r\n        <td>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">Dear $DevFirstName $DevLastName,</p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'"></p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">The password of your $OrganizationName API account has been reset, per your request.</p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">\r\n                Your new password is: <strong>$DevPassword</strong></p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">Please make sure to change it next time you sign in.</p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">Thank you,</p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">$OrganizationName API Team</p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">\r\n            <a href="$DevPortalUrl">$DevPortalUrl</a>\r\n          </p>\r\n        </td>\r\n      </tr>\r\n    </table>\r\n  </body>\r\n</html>'
    title: 'Password reset by publisher notification (Password reset by admin)'
    description: 'Developers receive this email when the publisher resets their password.'
    parameters: [
      {
        name: 'DevFirstName'
        title: 'Developer first name'
      }
      {
        name: 'DevLastName'
        title: 'Developer last name'
      }
      {
        name: 'DevPassword'
        title: 'New Developer password'
      }
      {
        name: 'OrganizationName'
        title: 'Organization name'
      }
      {
        name: 'DevPortalUrl'
        title: 'Developer portal URL'
      }
    ]
  }
}

resource service_isdf_apim_01_name_PasswordResetIdentityDefault 'Microsoft.ApiManagement/service/templates@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'PasswordResetIdentityDefault'
  properties: {
    subject: 'Your password change request'
    body: '<!DOCTYPE html >\r\n<html>\r\n  <head>\r\n    <meta charset="UTF-8" />\r\n    <title>Letter</title>\r\n  </head>\r\n  <body>\r\n    <table width="100%">\r\n      <tr>\r\n        <td>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">Dear $DevFirstName $DevLastName,</p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'"></p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">You are receiving this email because you requested to change the password on your $OrganizationName API account.</p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">Please click on the link below and follow instructions to create your new password:</p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">\r\n            <a id="resetUrl" href="$ConfirmUrl" style="text-decoration:none">\r\n              <strong>$ConfirmUrl</strong>\r\n            </a>\r\n          </p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">If clicking the link does not work, please copy-and-paste or re-type it into your browser\'s address bar and hit "Enter".</p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">Thank you,</p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">$OrganizationName API Team</p>\r\n          <p style="font-size:12pt;font-family:\'Segoe UI\'">\r\n            <a href="$DevPortalUrl">$DevPortalUrl</a>\r\n          </p>\r\n        </td>\r\n      </tr>\r\n    </table>\r\n  </body>\r\n</html>'
    title: 'Password change confirmation'
    description: 'Developers receive this email when they request a password change of their account. The purpose of the email is to verify that the account owner made the request and to provide a one-time perishable URL for changing the password.'
    parameters: [
      {
        name: 'DevFirstName'
        title: 'Developer first name'
      }
      {
        name: 'DevLastName'
        title: 'Developer last name'
      }
      {
        name: 'OrganizationName'
        title: 'Organization name'
      }
      {
        name: 'DevPortalUrl'
        title: 'Developer portal URL'
      }
      {
        name: 'ConfirmUrl'
        title: 'Developer new password instruction URL'
      }
      {
        name: 'DevPortalHost'
        title: 'Developer portal hostname'
      }
      {
        name: 'ConfirmQuery'
        title: 'Query string part of the instruction URL'
      }
    ]
  }
}

resource service_isdf_apim_01_name_PurchaseDeveloperNotificationMessage 'Microsoft.ApiManagement/service/templates@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'PurchaseDeveloperNotificationMessage'
  properties: {
    subject: 'Your subscription to the $ProdName'
    body: '<!DOCTYPE html >\r\n<html>\r\n  <head />\r\n  <body>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">Greetings $DevFirstName $DevLastName!</p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">\r\n          Thank you for subscribing to the <a href="http://$DevPortalUrl/products/$ProdId"><strong>$ProdName</strong></a> and welcome to the $OrganizationName developer community. We are delighted to have you as part of the team and are looking forward to the amazing applications you will build using our API!\r\n        </p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">Below are a few subscription details for your reference:</p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">\r\n      <ul>\r\n            #if ($SubStartDate != "")\r\n            <li style="font-size:12pt;font-family:\'Segoe UI\'">Start date: $SubStartDate</li>\r\n            #end\r\n            \r\n            #if ($SubTerm != "")\r\n            <li style="font-size:12pt;font-family:\'Segoe UI\'">Subscription term: $SubTerm</li>\r\n            #end\r\n          </ul>\r\n    </p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">\r\n            Visit the developer <a href="http://$DevPortalUrl/developer">profile area</a> to manage your subscription and subscription keys\r\n        </p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">A couple of pointers to help get you started:</p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">\r\n      <strong>\r\n        <a href="http://$DevPortalUrl/docs/services?product=$ProdId">Learn about the API</a>\r\n      </strong>\r\n    </p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">The API documentation provides all information necessary to make a request and to process a response. Code samples are provided per API operation in a variety of languages. Moreover, an interactive console allows making API calls directly from the developer portal without writing any code.</p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">\r\n      <strong>\r\n        <a href="http://$DevPortalUrl/applications">Feature your app in the app gallery</a>\r\n      </strong>\r\n    </p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">You can publish your application on our gallery for increased visibility to potential new users.</p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">\r\n      <strong>\r\n        <a href="http://$DevPortalUrl/issues">Stay in touch</a>\r\n      </strong>\r\n    </p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">\r\n          If you have an issue, a question, a suggestion, a request, or if you just want to tell us something, go to the <a href="http://$DevPortalUrl/issues">Issues</a> page on the developer portal and create a new topic.\r\n        </p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">Happy hacking,</p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">The $OrganizationName API Team</p>\r\n    <a style="font-size:12pt;font-family:\'Segoe UI\'" href="http://$DevPortalUrl">$DevPortalUrl</a>\r\n  </body>\r\n</html>'
    title: 'New subscription activated'
    description: 'Developers receive this acknowledgement email after subscribing to a product.'
    parameters: [
      {
        name: 'DevFirstName'
        title: 'Developer first name'
      }
      {
        name: 'DevLastName'
        title: 'Developer last name'
      }
      {
        name: 'ProdId'
        title: 'Product ID'
      }
      {
        name: 'ProdName'
        title: 'Product name'
      }
      {
        name: 'OrganizationName'
        title: 'Organization name'
      }
      {
        name: 'SubStartDate'
        title: 'Subscription start date'
      }
      {
        name: 'SubTerm'
        title: 'Subscription term'
      }
      {
        name: 'DevPortalUrl'
        title: 'Developer portal URL'
      }
    ]
  }
}

resource service_isdf_apim_01_name_QuotaLimitApproachingDeveloperNotificationMessage 'Microsoft.ApiManagement/service/templates@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'QuotaLimitApproachingDeveloperNotificationMessage'
  properties: {
    subject: 'You are approaching an API quota limit'
    body: '<!DOCTYPE html >\r\n<html>\r\n  <head>\r\n    <style>\r\n          body {font-size:12pt; font-family:"Segoe UI","Segoe WP","Tahoma","Arial","sans-serif";}\r\n          .alert { color: red; }\r\n          .child1 { padding-left: 20px; }\r\n          .child2 { padding-left: 40px; }\r\n          .number { text-align: right; }\r\n          .text { text-align: left; }\r\n          th, td { padding: 4px 10px; min-width: 100px; }\r\n          th { background-color: #DDDDDD;}\r\n        </style>\r\n  </head>\r\n  <body>\r\n    <p>Greetings $DevFirstName $DevLastName!</p>\r\n    <p>\r\n          You are approaching the quota limit on you subscription to the <strong>$ProdName</strong> product (primary key $SubPrimaryKey).\r\n          #if ($QuotaResetDate != "")\r\n          This quota will be renewed on $QuotaResetDate.\r\n          #else\r\n          This quota will not be renewed.\r\n          #end\r\n        </p>\r\n    <p>Below are details on quota usage for the subscription:</p>\r\n    <p>\r\n      <table>\r\n        <thead>\r\n          <th class="text">Quota Scope</th>\r\n          <th class="number">Calls</th>\r\n          <th class="number">Call Quota</th>\r\n          <th class="number">Bandwidth</th>\r\n          <th class="number">Bandwidth Quota</th>\r\n        </thead>\r\n        <tbody>\r\n          <tr>\r\n            <td class="text">Subscription</td>\r\n            <td class="number">\r\n                  #if ($CallsAlert == true)\r\n                  <span class="alert">$Calls</span>\r\n                  #else\r\n                  $Calls\r\n                  #end\r\n                </td>\r\n            <td class="number">$CallQuota</td>\r\n            <td class="number">\r\n                  #if ($BandwidthAlert == true)\r\n                  <span class="alert">$Bandwidth</span>\r\n                  #else\r\n                  $Bandwidth\r\n                  #end\r\n                </td>\r\n            <td class="number">$BandwidthQuota</td>\r\n          </tr>\r\n              #foreach ($api in $Apis)\r\n              <tr><td class="child1 text">API: $api.Name</td><td class="number">\r\n                  #if ($api.CallsAlert == true)\r\n                  <span class="alert">$api.Calls</span>\r\n                  #else\r\n                  $api.Calls\r\n                  #end\r\n                </td><td class="number">$api.CallQuota</td><td class="number">\r\n                  #if ($api.BandwidthAlert == true)\r\n                  <span class="alert">$api.Bandwidth</span>\r\n                  #else\r\n                  $api.Bandwidth\r\n                  #end\r\n                </td><td class="number">$api.BandwidthQuota</td></tr>\r\n              #foreach ($operation in $api.Operations)\r\n              <tr><td class="child2 text">Operation: $operation.Name</td><td class="number">\r\n                  #if ($operation.CallsAlert == true)\r\n                  <span class="alert">$operation.Calls</span>\r\n                  #else\r\n                  $operation.Calls\r\n                  #end\r\n                </td><td class="number">$operation.CallQuota</td><td class="number">\r\n                  #if ($operation.BandwidthAlert == true)\r\n                  <span class="alert">$operation.Bandwidth</span>\r\n                  #else\r\n                  $operation.Bandwidth\r\n                  #end\r\n                </td><td class="number">$operation.BandwidthQuota</td></tr>\r\n              #end\r\n              #end\r\n            </tbody>\r\n      </table>\r\n    </p>\r\n    <p>Thank you,</p>\r\n    <p>$OrganizationName API Team</p>\r\n    <a href="$DevPortalUrl">$DevPortalUrl</a>\r\n    <p />\r\n  </body>\r\n</html>'
    title: 'Developer quota limit approaching notification'
    description: 'Developers receive this email to alert them when they are approaching a quota limit.'
    parameters: [
      {
        name: 'DevFirstName'
        title: 'Developer first name'
      }
      {
        name: 'DevLastName'
        title: 'Developer last name'
      }
      {
        name: 'ProdName'
        title: 'Product name'
      }
      {
        name: 'OrganizationName'
        title: 'Organization name'
      }
      {
        name: 'SubPrimaryKey'
        title: 'Primary Subscription key'
      }
      {
        name: 'DevPortalUrl'
        title: 'Developer portal URL'
      }
      {
        name: 'QuotaResetDate'
        title: 'Quota reset date'
      }
    ]
  }
}

resource service_isdf_apim_01_name_RejectDeveloperNotificationMessage 'Microsoft.ApiManagement/service/templates@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'RejectDeveloperNotificationMessage'
  properties: {
    subject: 'Your subscription request for the $ProdName'
    body: '<!DOCTYPE html >\r\n<html>\r\n  <head />\r\n  <body>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">Dear $DevFirstName $DevLastName,</p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">\r\n          We would like to inform you that we reviewed your subscription request for the <strong>$ProdName</strong>.\r\n        </p>\r\n        #if ($SubDeclineReason == "")\r\n        <p style="font-size:12pt;font-family:\'Segoe UI\'">Regretfully, we were unable to approve it, as subscriptions are temporarily suspended at this time.</p>\r\n        #else\r\n        <p style="font-size:12pt;font-family:\'Segoe UI\'">\r\n          Regretfully, we were unable to approve it at this time for the following reason:\r\n          <div style="margin-left: 1.5em;"> $SubDeclineReason </div></p>\r\n        #end\r\n        <p style="font-size:12pt;font-family:\'Segoe UI\'"> We truly appreciate your interest. </p><p style="font-size:12pt;font-family:\'Segoe UI\'">All the best,</p><p style="font-size:12pt;font-family:\'Segoe UI\'">The $OrganizationName API Team</p><a style="font-size:12pt;font-family:\'Segoe UI\'" href="http://$DevPortalUrl">$DevPortalUrl</a></body>\r\n</html>'
    title: 'Subscription request declined'
    description: 'This email is sent to developers when their subscription requests for products requiring publisher approval is declined.'
    parameters: [
      {
        name: 'DevFirstName'
        title: 'Developer first name'
      }
      {
        name: 'DevLastName'
        title: 'Developer last name'
      }
      {
        name: 'SubDeclineReason'
        title: 'Reason for declining subscription'
      }
      {
        name: 'ProdName'
        title: 'Product name'
      }
      {
        name: 'OrganizationName'
        title: 'Organization name'
      }
      {
        name: 'DevPortalUrl'
        title: 'Developer portal URL'
      }
    ]
  }
}

resource service_isdf_apim_01_name_RequestDeveloperNotificationMessage 'Microsoft.ApiManagement/service/templates@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'RequestDeveloperNotificationMessage'
  properties: {
    subject: 'Your subscription request for the $ProdName'
    body: '<!DOCTYPE html >\r\n<html>\r\n  <head />\r\n  <body>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">Dear $DevFirstName $DevLastName,</p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">\r\n          Thank you for your interest in our <strong>$ProdName</strong> API product!\r\n        </p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">\r\n          We were delighted to receive your subscription request. We will promptly review it and get back to you at <strong>$DevEmail</strong>.\r\n        </p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">Thank you,</p>\r\n    <p style="font-size:12pt;font-family:\'Segoe UI\'">The $OrganizationName API Team</p>\r\n    <a style="font-size:12pt;font-family:\'Segoe UI\'" href="http://$DevPortalUrl">$DevPortalUrl</a>\r\n  </body>\r\n</html>'
    title: 'Subscription request received'
    description: 'This email is sent to developers to acknowledge receipt of their subscription requests for products requiring publisher approval.'
    parameters: [
      {
        name: 'DevFirstName'
        title: 'Developer first name'
      }
      {
        name: 'DevLastName'
        title: 'Developer last name'
      }
      {
        name: 'DevEmail'
        title: 'Developer email'
      }
      {
        name: 'ProdName'
        title: 'Product name'
      }
      {
        name: 'OrganizationName'
        title: 'Organization name'
      }
      {
        name: 'DevPortalUrl'
        title: 'Developer portal URL'
      }
    ]
  }
}

resource service_isdf_apim_01_name_1 'Microsoft.ApiManagement/service/users@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: '1'
  properties: {
    firstName: 'Administrator'
    email: 'ADMIN_EMAIL'
    state: 'active'
    identities: [
      {
        provider: 'Azure'
        id: 'ADMIN_EMAIL'
      }
    ]
    lastName: users_1_lastName
  }
}

resource service_isdf_apim_01_name_echo_api_create_resource 'Microsoft.ApiManagement/service/apis/operations@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_echo_api
  name: 'create-resource'
  properties: {
    displayName: 'Create resource'
    method: 'POST'
    urlTemplate: '/resource'
    templateParameters: []
    description: 'A demonstration of a POST call based on the echo backend above. The request body is expected to contain JSON-formatted data (see example below). A policy is used to automatically transform any request sent in JSON directly to XML. In a real-world scenario this could be used to enable modern clients to speak to a legacy backend.'
    request: {
      queryParameters: []
      headers: []
      representations: [
        {
          contentType: 'application/json'
          examples: {
            default: {
              value: '{\r\n\t"vehicleType": "train",\r\n\t"maxSpeed": 125,\r\n\t"avgSpeed": 90,\r\n\t"speedUnit": "mph"\r\n}'
            }
          }
        }
      ]
    }
    responses: [
      {
        statusCode: 200
        representations: []
        headers: []
      }
    ]
  }
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_isdfwriter_la_isdf 'Microsoft.ApiManagement/service/apis/operations@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_isdfwriter_la
  name: 'isdf'
  properties: {
    displayName: 'isdf'
    method: 'POST'
    urlTemplate: '/isdf'
    templateParameters: []
    description: 'Trigger a run of the logic app.'
    request: {
      description: 'The request body.'
      queryParameters: []
      headers: []
      representations: [
        {
          contentType: 'application/json'
          examples: {
            default: {
              value: {
                device: {
                  aadDeviceId: 'string'
                  hostname: 'string'
                  aadTenantId: 'string'
                }
                isdf: {
                  channel: 'ISDF:W365'
                  ea2: 'string'
                  signalHash: 'string'
                  originTupleHash: 'string'
                  baselineVer: 0
                  timestampUtc: 'string'
                }
              }
            }
          }
          schemaId: '68ae915446346115e8077ade'
          typeName: 'request-isdf'
        }
      ]
    }
    responses: [
      {
        statusCode: 200
        description: 'The Logic App successfully processed the payload.'
        representations: [
          {
            contentType: 'application/json'
            examples: {
              default: {
                value: {
                  syncResult: 'Success'
                  processedAtUtc: '2025-08-27T08:15:30Z'
                  echo: {
                    aadDeviceId: 'd66f6a69-e764-4c42-a4b8-7f538123c517'
                  }
                }
              }
            }
            schemaId: '68ae915446346115e8077ade'
            typeName: 'isdfPost200ApplicationJsonResponse'
          }
        ]
        headers: []
      }
      {
        statusCode: 400
        description: 'The Logic App rejected the payload.'
        representations: [
          {
            contentType: 'application/json'
            examples: {
              default: {
                value: {
                  syncResult: 'Failure'
                  error: 'Invalid signalHash format'
                  processedAtUtc: '2025-08-27T08:15:30Z'
                }
              }
            }
            schemaId: '68ae915446346115e8077ade'
            typeName: 'isdfPost400ApplicationJsonResponse'
          }
        ]
        headers: []
      }
    ]
  }
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_echo_api_modify_resource 'Microsoft.ApiManagement/service/apis/operations@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_echo_api
  name: 'modify-resource'
  properties: {
    displayName: 'Modify Resource'
    method: 'PUT'
    urlTemplate: '/resource'
    templateParameters: []
    description: 'A demonstration of a PUT call handled by the same "echo" backend as above. You can now specify a request body in addition to headers and it will be returned as well.'
    responses: [
      {
        statusCode: 200
        representations: []
        headers: []
      }
    ]
  }
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_echo_api_remove_resource 'Microsoft.ApiManagement/service/apis/operations@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_echo_api
  name: 'remove-resource'
  properties: {
    displayName: 'Remove resource'
    method: 'DELETE'
    urlTemplate: '/resource'
    templateParameters: []
    description: 'A demonstration of a DELETE call which traditionally deletes the resource. It is based on the same "echo" backend as in all other operations so nothing is actually deleted.'
    responses: [
      {
        statusCode: 200
        representations: []
        headers: []
      }
    ]
  }
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_echo_api_retrieve_header_only 'Microsoft.ApiManagement/service/apis/operations@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_echo_api
  name: 'retrieve-header-only'
  properties: {
    displayName: 'Retrieve header only'
    method: 'HEAD'
    urlTemplate: '/resource'
    templateParameters: []
    description: 'The HEAD operation returns only headers. In this demonstration a policy is used to set additional headers when the response is returned and to enable JSONP.'
    responses: [
      {
        statusCode: 200
        representations: []
        headers: []
      }
    ]
  }
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_echo_api_retrieve_resource 'Microsoft.ApiManagement/service/apis/operations@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_echo_api
  name: 'retrieve-resource'
  properties: {
    displayName: 'Retrieve resource'
    method: 'GET'
    urlTemplate: '/resource'
    templateParameters: []
    description: 'A demonstration of a GET call on a sample resource. It is handled by an "echo" backend which returns a response equal to the request (the supplied headers and body are being returned as received).'
    request: {
      queryParameters: [
        {
          name: 'param1'
          description: 'A sample parameter that is required and has a default value of "sample".'
          type: 'string'
          defaultValue: 'sample'
          required: true
          values: [
            'sample'
          ]
        }
        {
          name: 'param2'
          description: 'Another sample parameter, set to not required.'
          type: 'number'
          values: []
        }
      ]
      headers: []
      representations: []
    }
    responses: [
      {
        statusCode: 200
        description: 'Returned in all cases.'
        representations: []
        headers: []
      }
    ]
  }
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_echo_api_retrieve_resource_cached 'Microsoft.ApiManagement/service/apis/operations@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_echo_api
  name: 'retrieve-resource-cached'
  properties: {
    displayName: 'Retrieve resource (cached)'
    method: 'GET'
    urlTemplate: '/resource-cached'
    templateParameters: []
    description: 'A demonstration of a GET call with caching enabled on the same "echo" backend as above. Cache TTL is set to 1 hour. When you make the first request the headers you supplied will be cached. Subsequent calls will return the same headers as the first time even if you change them in your request.'
    request: {
      queryParameters: [
        {
          name: 'param1'
          description: 'A sample parameter that is required and has a default value of "sample".'
          type: 'string'
          defaultValue: 'sample'
          required: true
          values: [
            'sample'
          ]
        }
        {
          name: 'param2'
          description: 'Another sample parameter, set to not required.'
          type: 'string'
          values: []
        }
      ]
      headers: []
      representations: []
    }
    responses: [
      {
        statusCode: 200
        representations: []
        headers: []
      }
    ]
  }
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_isdfwriter_la_68ae915446346115e8077ade 'Microsoft.ApiManagement/service/apis/schemas@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_isdfwriter_la
  name: '68ae915446346115e8077ade'
  properties: {
    contentType: 'application/vnd.oai.openapi.components+json'
    document: {}
  }
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_echo_api_default 'Microsoft.ApiManagement/service/apis/wikis@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_echo_api
  name: 'default'
  properties: {
    documents: []
  }
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_isdfwriter_la_default 'Microsoft.ApiManagement/service/apis/wikis@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_isdfwriter_la
  name: 'default'
  properties: {
    documents: []
  }
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_isdf_be_pool 'Microsoft.ApiManagement/service/backends@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'isdf-be-pool'
  properties: {
    type: 'Pool'
    pool: {
      services: [
        {
          id: service_isdf_apim_01_name_la_isdf_direct.id
          weight: 0
          priority: 0
        }
      ]
    }
    url: backends_isdf_be_pool_url
    protocol: backends_isdf_be_pool_protocol
  }
}

resource Microsoft_ApiManagement_service_diagnostics_service_isdf_apim_01_name_azuremonitor 'Microsoft.ApiManagement/service/diagnostics@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: 'azuremonitor'
  properties: {
    logClientIp: true
    loggerId: service_isdf_apim_01_name_azuremonitor.id
    sampling: {
      samplingType: 'fixed'
      percentage: json('100')
    }
    frontend: {
      request: {
        dataMasking: {
          queryParams: [
            {
              value: '*'
              mode: 'Hide'
            }
          ]
        }
      }
    }
    backend: {
      request: {
        dataMasking: {
          queryParams: [
            {
              value: '*'
              mode: 'Hide'
            }
          ]
        }
      }
    }
  }
}

resource service_isdf_apim_01_name_azuremonitor_azuremonitor 'Microsoft.ApiManagement/service/diagnostics/loggers@2018-01-01' = {
  parent: Microsoft_ApiManagement_service_diagnostics_service_isdf_apim_01_name_azuremonitor
  name: 'azuremonitor'
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_administrators_1 'Microsoft.ApiManagement/service/groups/users@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_administrators
  name: '1'
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_developers_1 'Microsoft.ApiManagement/service/groups/users@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_developers
  name: '1'
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_starter_echo_api 'Microsoft.ApiManagement/service/products/apis@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_starter
  name: 'echo-api'
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_unlimited_echo_api 'Microsoft.ApiManagement/service/products/apis@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_unlimited
  name: 'echo-api'
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_starter_administrators 'Microsoft.ApiManagement/service/products/groups@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_starter
  name: 'administrators'
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_unlimited_administrators 'Microsoft.ApiManagement/service/products/groups@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_unlimited
  name: 'administrators'
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_starter_developers 'Microsoft.ApiManagement/service/products/groups@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_starter
  name: 'developers'
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_unlimited_developers 'Microsoft.ApiManagement/service/products/groups@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_unlimited
  name: 'developers'
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_starter_guests 'Microsoft.ApiManagement/service/products/groups@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_starter
  name: 'guests'
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_unlimited_guests 'Microsoft.ApiManagement/service/products/groups@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_unlimited
  name: 'guests'
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_starter_policy 'Microsoft.ApiManagement/service/products/policies@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_starter
  name: 'policy'
  properties: {
    value: '<!--\r\n            IMPORTANT:\r\n            - Policy elements can appear only within the <inbound>, <outbound>, <backend> section elements.\r\n            - Only the <forward-request> policy element can appear within the <backend> section element.\r\n            - To apply a policy to the incoming request (before it is forwarded to the backend service), place a corresponding policy element within the <inbound> section element.\r\n            - To apply a policy to the outgoing response (before it is sent back to the caller), place a corresponding policy element within the <outbound> section element.\r\n            - To add a policy position the cursor at the desired insertion point and click on the round button associated with the policy.\r\n            - To remove a policy, delete the corresponding policy statement from the policy document.\r\n            - Position the <base> element within a section element to inherit all policies from the corresponding section element in the enclosing scope.\r\n            - Remove the <base> element to prevent inheriting policies from the corresponding section element in the enclosing scope.\r\n            - Policies are applied in the order of their appearance, from the top down.\r\n        -->\r\n<policies>\r\n  <inbound>\r\n    <rate-limit calls="5" renewal-period="60" />\r\n    <quota calls="100" renewal-period="604800" />\r\n    <base />\r\n  </inbound>\r\n  <backend>\r\n    <base />\r\n  </backend>\r\n  <outbound>\r\n    <base />\r\n  </outbound>\r\n</policies>'
    format: 'xml'
  }
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_starter_default 'Microsoft.ApiManagement/service/products/wikis@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_starter
  name: 'default'
  properties: {
    documents: []
  }
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_unlimited_default 'Microsoft.ApiManagement/service/products/wikis@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_unlimited
  name: 'default'
  properties: {
    documents: []
  }
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_echo_api_create_resource_policy 'Microsoft.ApiManagement/service/apis/operations/policies@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_echo_api_create_resource
  name: 'policy'
  properties: {
    value: '<policies>\r\n  <inbound>\r\n    <base />\r\n    <json-to-xml apply="always" consider-accept-header="false" />\r\n  </inbound>\r\n  <backend>\r\n    <base />\r\n  </backend>\r\n  <outbound>\r\n    <base />\r\n  </outbound>\r\n</policies>'
    format: 'xml'
  }
  dependsOn: [
    service_isdf_apim_01_name_echo_api
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_echo_api_retrieve_header_only_policy 'Microsoft.ApiManagement/service/apis/operations/policies@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_echo_api_retrieve_header_only
  name: 'policy'
  properties: {
    value: '<policies>\r\n  <inbound>\r\n    <base />\r\n  </inbound>\r\n  <backend>\r\n    <base />\r\n  </backend>\r\n  <outbound>\r\n    <base />\r\n    <set-header name="X-My-Sample" exists-action="override">\r\n      <value>This is a sample</value>\r\n      <!-- for multiple headers with the same name add additional value elements -->\r\n    </set-header>\r\n    <jsonp callback-parameter-name="ProcessResponse" />\r\n  </outbound>\r\n</policies>'
    format: 'xml'
  }
  dependsOn: [
    service_isdf_apim_01_name_echo_api
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_echo_api_retrieve_resource_cached_policy 'Microsoft.ApiManagement/service/apis/operations/policies@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_echo_api_retrieve_resource_cached
  name: 'policy'
  properties: {
    value: '<policies>\r\n  <inbound>\r\n    <base />\r\n    <cache-lookup vary-by-developer="false" vary-by-developer-groups="false">\r\n      <vary-by-header>Accept</vary-by-header>\r\n      <vary-by-header>Accept-Charset</vary-by-header>\r\n    </cache-lookup>\r\n    <rewrite-uri template="/resource" />\r\n  </inbound>\r\n  <backend>\r\n    <base />\r\n  </backend>\r\n  <outbound>\r\n    <base />\r\n    <cache-store duration="3600" />\r\n  </outbound>\r\n</policies>'
    format: 'xml'
  }
  dependsOn: [
    service_isdf_apim_01_name_echo_api
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_isdfwriter_la_isdf_policy 'Microsoft.ApiManagement/service/apis/operations/policies@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_isdfwriter_la_isdf
  name: 'policy'
  properties: {
    value: '<policies>\r\n  <inbound>\r\n    <base />\r\n    <!-- mTLS gate -->\r\n    <choose>\r\n      <when condition="@(context.Request.Certificate == null)">\r\n        <return-response>\r\n          <set-status code="401" reason="Client certificate required" />\r\n        </return-response>\r\n      </when>\r\n    </choose>\r\n    <choose>\r\n      <when condition="@{&#xA;        var c = context.Request.Certificate;&#xA;        var now = DateTime.UtcNow;&#xA;        bool timeOk = (now &gt;= c.NotBefore) &amp;&amp; (now &lt;= c.NotAfter);&#xA;        var issuer = c.Issuer ?? string.Empty;&#xA;        bool issuerOk = issuer.IndexOf(&quot;CN=ISS_CN&quot;, StringComparison.OrdinalIgnoreCase) &gt;= 0&#xA;                     || issuer.IndexOf(&quot;CN=ROOT_CN&quot;, StringComparison.OrdinalIgnoreCase) &gt;= 0;&#xA;        return !(timeOk &amp;&amp; issuerOk);&#xA;      }">\r\n        <return-response>\r\n          <set-status code="403" reason="Invalid client certificate" />\r\n        </return-response>\r\n      </when>\r\n    </choose>\r\n    <!-- mark + audit -->\r\n    <set-header name="x-from-apim" exists-action="override">\r\n      <value>1</value>\r\n    </set-header>\r\n    <set-header name="x-client-thumbprint" exists-action="override">\r\n      <value>@(context.Request.Certificate.Thumbprint)</value>\r\n    </set-header>\r\n    <set-header name="x-client-subject" exists-action="override">\r\n      <value>@(context.Request.Certificate.Subject)</value>\r\n    </set-header>\r\n    <set-header name="x-correlation-id" exists-action="override">\r\n      <value>@(context.RequestId.ToString())</value>\r\n    </set-header>\r\n    <set-header name="X-ARR-ClientCert" exists-action="delete" />\r\n    <authentication-managed-identity resource="APPREG_URI" />\r\n    <!-- Backend: host only; rewrite to /run; no SAS -->\r\n    <set-backend-service backend-id="la-isdf-direct" />\r\n    <rewrite-uri template="/workflows/WORKFLOW_ID/triggers/TRIGGER_NAME/paths/invoke" />\r\n    <set-query-parameter name="api-version" exists-action="override">\r\n      <value>2016-10-01</value>\r\n    </set-query-parameter>\r\n  </inbound>\r\n  <backend>\r\n    <retry count="3" interval="2" first-fast-retry="true" condition="@(&#xA;             context.Response == null ||&#xA;             (int)context.Response.StatusCode == 429 ||&#xA;             (int)context.Response.StatusCode &gt;= 500&#xA;           )">\r\n      <forward-request timeout="60" />\r\n    </retry>\r\n  </backend>\r\n  <outbound>\r\n    <base />\r\n    <set-header name="x-correlation-id" exists-action="override">\r\n      <value>@(context.RequestId.ToString())</value>\r\n    </set-header>\r\n  </outbound>\r\n  <on-error>\r\n    <base />\r\n  </on-error>\r\n</policies>'
    format: 'xml'
  }
  dependsOn: [
    service_isdf_apim_01_name_isdfwriter_la
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_starter_340616FF_867E_4CE8_BFDF_6F4CFDC2C4A4 'Microsoft.ApiManagement/service/products/apiLinks@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_starter
  name: '340616FF-867E-4CE8-BFDF-6F4CFDC2C4A4'
  properties: {
    apiId: service_isdf_apim_01_name_echo_api.id
  }
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_unlimited_955A3FC3_A199_4CA8_939C_948C7C1208F4 'Microsoft.ApiManagement/service/products/apiLinks@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_unlimited
  name: '955A3FC3-A199-4CA8-939C-948C7C1208F4'
  properties: {
    apiId: service_isdf_apim_01_name_echo_api.id
  }
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_starter_47E1F697_667F_49E4_A403_C3C9522FE264 'Microsoft.ApiManagement/service/products/groupLinks@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_starter
  name: '47E1F697-667F-49E4-A403-C3C9522FE264'
  properties: {
    groupId: service_isdf_apim_01_name_developers.id
  }
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_unlimited_60E23FEC_FED9_4E8D_AAD0_B52D8375B7F5 'Microsoft.ApiManagement/service/products/groupLinks@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_unlimited
  name: '60E23FEC-FED9-4E8D-AAD0-B52D8375B7F5'
  properties: {
    groupId: service_isdf_apim_01_name_guests.id
  }
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_unlimited_88F7913E_E70B_4B66_B996_62824934D69D 'Microsoft.ApiManagement/service/products/groupLinks@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_unlimited
  name: '88F7913E-E70B-4B66-B996-62824934D69D'
  properties: {
    groupId: service_isdf_apim_01_name_developers.id
  }
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_unlimited_BBBD5558_5392_4F35_925E_7902ED5CFB64 'Microsoft.ApiManagement/service/products/groupLinks@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_unlimited
  name: 'BBBD5558-5392-4F35-925E-7902ED5CFB64'
  properties: {
    groupId: service_isdf_apim_01_name_administrators.id
  }
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_starter_CF01CCFB_85CB_40DD_97F8_4F76F1B4D021 'Microsoft.ApiManagement/service/products/groupLinks@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_starter
  name: 'CF01CCFB-85CB-40DD-97F8-4F76F1B4D021'
  properties: {
    groupId: service_isdf_apim_01_name_administrators.id
  }
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_starter_FD732D2C_1CAD_490C_82CE_CA16E4F46639 'Microsoft.ApiManagement/service/products/groupLinks@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_starter
  name: 'FD732D2C-1CAD-490C-82CE-CA16E4F46639'
  properties: {
    groupId: service_isdf_apim_01_name_guests.id
  }
  dependsOn: [
    service_isdf_apim_01_name_resource
  ]
}

resource service_isdf_apim_01_name_68ac83b840fa460066070001 'Microsoft.ApiManagement/service/subscriptions@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: '68ac83b840fa460066070001'
  properties: {
    ownerId: service_isdf_apim_01_name_1.id
    scope: service_isdf_apim_01_name_starter.id
    state: 'active'
    allowTracing: false
    displayName: subscriptions_68ac83b840fa460066070001_displayName
  }
}

resource service_isdf_apim_01_name_68ac83b840fa460066070002 'Microsoft.ApiManagement/service/subscriptions@2024-06-01-preview' = {
  parent: service_isdf_apim_01_name_resource
  name: '68ac83b840fa460066070002'
  properties: {
    ownerId: service_isdf_apim_01_name_1.id
    scope: service_isdf_apim_01_name_unlimited.id
    state: 'active'
    allowTracing: false
    displayName: subscriptions_68ac83b840fa460066070002_displayName
  }
}
