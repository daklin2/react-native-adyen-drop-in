package com.reactnative.adyendropin;

import androidx.annotation.NonNull;

import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ViewManager;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;

public class AdyenDropInPaymentPackage implements ReactPackage {
    private AdyenDropInPayment adyenDropInPayment;
    @NonNull
    @Override
    public List<NativeModule> createNativeModules(@NonNull ReactApplicationContext reactContext) {
        adyenDropInPayment = new AdyenDropInPayment(reactContext);
        return Arrays.asList(new NativeModule[]{
                adyenDropInPayment,
        });
    }

    public AdyenDropInPayment getAdyenDropInPayment() {
        return adyenDropInPayment;
    }

    @NonNull
    @Override
    public List<ViewManager> createViewManagers(@NonNull ReactApplicationContext reactContext) {
        return Collections.emptyList();
    }
}
