ReactionCore.registerPackage
  name: 'reaction-braintree' # usually same as meteor package
  autoEnable: false # auto-enable in dashboard
  settings: # private package settings config (blackbox)
    mode: false
    merchant_id: ""
    public_key: ""
    private_key: ""
  registry: [
    # all options except route and template
    # are used to describe the
    # dashboard 'app card'.
    {
      provides: 'dashboard'
      label: 'Braintree'
      description: "Braintree Payment for Reaction Commerce"
      icon: 'fa fa-credit-card' # glyphicon/fa
      cycle: '3' # Core, Stable, Testing (currently testing)
      container: 'dashboard'  #group this with settings
    }
    # configures settings link for app card
    # use 'group' to link to dashboard card
    {
      route: 'braintree'
      provides: 'settings'
      container: 'dashboard'
    }
    # configures template for checkout
    # paymentMethod dynamic template
    {
      template: 'braintreePaymentForm'
      provides: 'paymentMethod'
    }
  ]
  # array of permission objects
  permissions: [
    {
      label: "Braintree"
      permission: "dashboard/payments"
      group: "Shop Settings"
    }
  ]
