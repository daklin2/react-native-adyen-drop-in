package com.reactnative.adyendropin;

import android.content.Intent;
import android.util.Log;

import androidx.annotation.NonNull;

import com.adyen.checkout.components.ActionComponentData;
import com.adyen.checkout.components.PaymentComponentState;
import com.adyen.checkout.components.model.payments.response.Action;
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
        DropInServiceResult result = handleResponse(paymentComponentJson);
        sendResult(result);
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

    protected DropInServiceResult handleResponse (JSONObject jsonObject) {
        DropInServiceResult result;
        Action action = Action.SERIALIZER.deserialize(jsonObject);
        if (jsonObject == null) {
            result = new DropInServiceResult.Error();
        } else if (isAction(jsonObject)) {
            result = new DropInServiceResult.Action(action);
        } else {
            result = new DropInServiceResult.Finished(jsonObject.toString());
        }
        return result;
    }
    public boolean isAction (JSONObject jsonObject) {
        return jsonObject.has("action");
    }
}
