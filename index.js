import { NativeEventEmitter, NativeModules, Platfrom } from "react-native";

const AdyenDropIn = NativeModules.AdyenDropInPayment;
const EventEmitter = new NativeEventEmitter(AdyenDropIn);
const eventMap = {};

const removeListener = (key) => {
  if (eventMap[key]) {
    eventMap[key].remove();
    delete eventMap[key]
  }
}

const addListener = (key, listener) => {
  removeListener(key);

  const eventEmitterSubscription = EventEmitter.addListener(key, listener);
  eventMap[key] = eventEmitterSubscription;
  return eventEmitterSubscription;
};


export default {
  /**
   * Starting payment process.
   * @returns {*}
   */
  configPayment(publicKey, env, showsStorePaymentMethodField) {
    if (Platform.OS === 'android') {
      return AdyenDropIn.configPayment(publicKey, env);
    }
    
    return AdyenDropIn.configPayment(publicKey, env, showsStorePaymentMethodField);
  },
  /**
   * list paymentMethods
   *
   * @param {String} encodedToken
   *
   * @returns {*}
   */
  paymentMethods(paymentMethodJson) {
    if (typeof paymentMethodJson === "object") {
      paymentMethodJson = JSON.stringify(paymentMethodJson);
    }
    this._validateParam(paymentMethodJson, "paymentMethods", "string");
    return AdyenDropIn.paymentMethods(paymentMethodJson);
  },
  /**
   * handle Action from payments
   * @param actionJson
   * @returns {*}
   */
  handleAction(actionJson) {
    if (typeof actionJson === "object") {
      actionJson = JSON.stringify(actionJson);
    }
    this._validateParam(actionJson, "handleAction", "string");
    return AdyenDropIn.handleAction(actionJson);
  },
  handlePaymentResult(paymentJson) {
    if (typeof paymentJson === "object") {
      paymentJson = JSON.stringify(paymentJson);
    }
    this._validateParam(paymentJson, "handlePaymentResult", "string");
    return AdyenDropIn.handlePaymentResult(paymentJson);
  },
  encryptCard(cardNumber, expiryMonth, expiryYear, securityCode) {
    return AdyenDropIn.encryptCard(
      cardNumber,
      expiryMonth,
      expiryYear,
      securityCode
    );
  },
  /**
   *  call when need to do more action
   */
  onPaymentProvide(mOnPaymentProvide) {
    this._validateParam(mOnPaymentProvide, "onPaymentProvide", "function");
      
    addListener("onPaymentProvide", e => {
      mOnPaymentProvide(e);
    });
  },
  // /**
  //  * call when cancel a payment
  //  * @param mOnPaymentCancel
  //  */
  // onPaymentCancel(mOnPaymentCancel) {
  //     this._validateParam(
  //         mOnPaymentCancel,
  //         'onPaymentCancel',
  //         'function',
  //     );
  //     onPaymentCancelListener = events.addListener(
  //         'mOnPaymentCancel',
  //         e => {
  //             mOnPaymentCancel(e);
  //         },
  //     );
  // },
  /**
   * call when payment fail
   * @param {mOnError} mOnError
   */
  onPaymentFail(mOnPaymentFail) {
    this._validateParam(mOnPaymentFail, "onPaymentFail", "function");

    addListener("onPaymentFail", e => {
      mOnPaymentFail(e);
    });
  },
  /**
   * call when payment submit ,send to server do payments
   */
  onPaymentSubmit(mOnPaymentSubmit) {
    this._validateParam(mOnPaymentSubmit, "onPaymentSubmit", "function");

    addListener("onPaymentSubmit", e => {
      mOnPaymentSubmit(e);
    });
  },

  /**
   * @param {*} param
   * @param {String} methodName
   * @param {String} requiredType
   * @private
   */
  _validateParam(param, methodName, requiredType) {
    if (typeof param !== requiredType) {
      throw new Error(
        `Error: AdyenDropIn.${methodName}() requires a ${
          requiredType === "function" ? "callback function" : requiredType
        } but got a ${typeof param}`
      );
    }
  },
  events: EventEmitter,
  removeListeners() {
    Object.keys(eventMap).forEach((key) => {
      removeListener(key)
    }) 
  }
};
