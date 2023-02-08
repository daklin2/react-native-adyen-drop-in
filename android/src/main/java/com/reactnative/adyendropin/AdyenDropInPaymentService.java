package com.reactnative.adyendropin;

import androidx.annotation.NonNull;

import com.adyen.checkout.components.ActionComponentData;
import com.adyen.checkout.components.PaymentComponentState;
import com.adyen.checkout.dropin.service.DropInService;
import com.adyen.checkout.dropin.service.DropInServiceResult;

import org.json.JSONObject;

public class AdyenDropInPaymentService extends DropInService {
    public AdyenDropInPaymentService() {
        AdyenDropInPayment.dropInService = this;
    }

    @Override
    protected void onPaymentsCallRequested(@NonNull PaymentComponentState<?> paymentComponentState, @NonNull JSONObject paymentComponentJson) {
        if (paymentComponentJson == null) {
            sendResult(new DropInServiceResult.Finished(""));
        }
        if (AdyenDropInPayment.INSTANCE != null) {
            AdyenDropInPayment.INSTANCE.handlePaymentSubmit(paymentComponentState);
        }
    }

    @Override
    protected void onDetailsCallRequested(@NonNull ActionComponentData actionComponentData, @NonNull JSONObject actionComponentJson) {
        if (actionComponentJson == null) {
            DropInServiceResult res = new DropInServiceResult.Finished("");
            sendResult(res);
        }
        if (AdyenDropInPayment.INSTANCE != null) {
            AdyenDropInPayment.INSTANCE.handlePaymentProvide(actionComponentData);
        }
    }

    protected void handleResult (DropInServiceResult result) {
        sendResult(result);
    }

    public boolean isAction (JSONObject jsonObject) {
        return jsonObject.has("action");
    }
}
