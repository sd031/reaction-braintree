ReactionCore.registerPackage
  name: "reaction-braintree"
  provides: ['paymentMethod']
  paymentTemplate: "braintreePaymentForm"
  label: "Braintree"
  description: "Braintree Payment for Reaction Commerce"
  icon: 'fa fa-shopping-cart'
  settingsRoute: "braintree"
  hasWidget: true
  priority: "2"
  shopPermissions: [
    {
      label: "Braintree Payments"
      permission: "dashboard/payments"
      group: "Shop Settings"
    }
  ]