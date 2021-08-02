import { NativeEventEmitter, NativeModules, Platfrom } from "react-native";

const AdyenDropIn = NativeModules.AdyenDropInPayment;
const EventEmitter = new NativeEventEmitter(AdyenDropIn);
const eventMap = {};
let onPaymentProvideListener;
let onPaymentFailListener;
let onPaymentSubmitListener;
let onPaymentCancelListener;
const addListener = (key, listener) => {
  if (eventMap[key]) {
    return eventMap[key];
  }
  const eventEmitterListener = EventEmitter.addListener(key, listener);
  eventMap[key] = eventEmitterListener;
  return eventEmitterListener;
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

    if (onPaymentProvideListener) {
      EventEmitter.removeListener(onPaymentProvideListener);
      delete eventMap["onPaymentProvide"]
    }
    onPaymentProvideListener = addListener("onPaymentProvide", e => {
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
    if (onPaymentFailListener) {
      EventEmitter.removeListener(onPaymentFailListener);
      delete eventMap["onPaymentFail"]
    }
    onPaymentFailListener = addListener("onPaymentFail", e => {
      mOnPaymentFail(e);
    });
  },
  /**
   * call when payment submit ,send to server do payments
   */
  onPaymentSubmit(mOnPaymentSubmit) {
    this._validateParam(mOnPaymentSubmit, "onPaymentSubmit", "function");
    if (onPaymentSubmitListener) {
      EventEmitter.removeListener(onPaymentSubmitListener);
      delete eventMap["onPaymentSubmit"]
    }
    onPaymentSubmitListener = addListener("onPaymentSubmit", e => {
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
    if (onPaymentProvideListener) {
      onPaymentProvideListener.remove();
      EventEmitter.removeListener(onPaymentProvideListener);
    }
    if (onPaymentFailListener) {
      onPaymentFailListener.remove();
      EventEmitter.removeListener(onPaymentFailListener);
    }
    if (onPaymentSubmitListener) {
      onPaymentSubmitListener.remove();
      EventEmitter.removeListener(onPaymentSubmitListener);
    }
    if (onPaymentCancelListener) {
      onPaymentCancelListener.remove();
      EventEmitter.removeListener(onPaymentCancelListener);
    }

    if (eventMap["onPaymentProvide"]) {
      delete eventMap["onPaymentProvide"]
    }

    if (eventMap["onPaymentFail"]) {
      delete eventMap["onPaymentFail"]
    }

    if (eventMap["onPaymentSubmit"]) {
      delete eventMap["onPaymentSubmit"]
    }
  }
};
