uiEnd = (template, buttonText) ->
  template.$(":input").removeAttr("disabled")
  template.$("#btn-complete-order").text(buttonText)
  template.$("#btn-processing").addClass("hidden")

paymentAlert = (errorMessage) ->
  $(".alert").removeClass("hidden").text(errorMessage)

hidePaymentAlert = () ->
  $(".alert").addClass("hidden").text('')

handleBraintreeSubmitError = (error) ->
  # TODO - this error handling needs to be reworked for the Braintree API
  console.log error
  # Depending on what they are, errors come back from Braintree in various formats
  # singleError = error?.response?.error_description
  # serverError = error?.response?.message
  # errors = error?.response?.details || []
  # if singleError
  #   paymentAlert("Oops! " + singleError)
  # else if errors.length
  #   for error in errors
  #     formattedError = "Oops! " + error.issue + ": " + error.field.split(/[. ]+/).pop().replace(/_/g,' ')
  #     paymentAlert(formattedError)
  # else if serverError
  #   paymentAlert("Oops! " + serverError)

# used to track asynchronous submitting for UI changes
submitting = false

AutoForm.addHooks "braintree-payment-form",
  onSubmit: (doc) ->
    # Process form (pre-validated by autoform)
    submitting = true
    template = this.template
    hidePaymentAlert()

    # Format data for braintree
    form = {
      name: doc.payerName
      number: doc.cardNumber
      expirationMonth: doc.expireMonth
      expirationYear: doc.expireYear
      cvv2: doc.cvv
      type: getCardType(doc.cardNumber)
    }

    # Reaction only stores type and 4 digits
    storedCard = form.type.charAt(0).toUpperCase() + form.type.slice(1) + " " + doc.cardNumber.slice(-4)

    # Submit for processing
    Meteor.Braintree.authorize form,
      total: ReactionCore.Collections.Cart.findOne().cartTotal()
      currency: Shops.findOne().currency
    , (error, transaction) ->
      submitting = false

      if error
        # this only catches connection/authentication errors
        handleBraintreeSubmitError(error)
        # Hide processing UI
        uiEnd(template, "Resubmit payment")
        return
      else
        if transaction.saved is true #successful transaction

          # Normalize status
          normalizedStatus = switch transaction.response.transaction.status
            when "authorization_expired" then "expired"
            when "authorized" then "created"
            when "authorizing" then "pending"
            when "settlement_pending" then "pending"
            when "settlement_confirmed" then "settled"
            when "settlement_declined" then "failed"
            when "failed" then "failed"
            when "gateway_rejected" then "failed"
            when "processor_declined" then "failed"
            when "settled" then "settled"
            when "settling" then "pending"
            when "submitted_for_settlement" then "pending"
            when "voided" then "voided"
            else "failed"

          # Normalize mode
          normalizedMode = switch transaction.response.transaction.status
            when "settled" then "capture"
            when "settling" then "capture"
            when "submitted_for_settlement" then "capture"
            when "settlement_confirmed" then "capture"
            when "authorized" or "authorizing" then "authorize"
            else "capture"

          # Response object to pass to CartWorkflow
          paymentMethod =
            processor: "Braintree"
            storedCard: storedCard
            method: transaction.response.transaction.creditCard.cardType
            transactionId: transaction.response.transaction.id
            amount: transaction.response.transaction.amount
            status: normalizedStatus
            mode: normalizedMode
            createdAt: new Date(transaction.response.create_time)
            updatedAt: new Date(transaction.response.update_time)
            transactions: []
          paymentMethod.transactions.push transaction.response

          # Store transaction information with order
          # paymentMethod will auto transition to
          # CartWorkflow.paymentAuth() which
          # will create order, clear the cart, and update inventory,
          # and goto order confirmation page
          CartWorkflow.paymentMethod(paymentMethod)
          return
        else # card errors are returned in transaction
          handleBraintreeSubmitError(transaction.response.message)
          # Hide processing UI
          uiEnd(template, "Resubmit payment")
          return

    return false;

  beginSubmit: (formId, template) ->
    # Show Processing
    template.$(":input").attr("disabled", true)
    template.$("#btn-complete-order").text("Submitting ")
    template.$("#btn-processing").removeClass("hidden")
  endSubmit: (formId, template) ->
    # Hide processing UI here if form was not valid
    uiEnd(template, "Complete your order") if not submitting
