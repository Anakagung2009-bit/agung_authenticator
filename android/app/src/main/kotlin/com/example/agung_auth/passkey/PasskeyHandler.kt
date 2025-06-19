package com.example.agung_auth.passkey

import android.app.Activity
import android.content.Context
import android.util.Base64
import android.util.Log
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetCredentialResponse
import androidx.credentials.CredentialManager
import androidx.credentials.PasswordCredential
import androidx.credentials.PublicKeyCredential
import androidx.credentials.GetPublicKeyCredentialOption
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch

object PasskeyHandler {
    fun handlePasskeyLogin(context: Context, fidoData: String, onSuccess: (String) -> Unit, onError: (String) -> Unit) {
        val activity = context as? Activity ?: return onError("Invalid activity context")

        try {
            val fidoJson = String(Base64.decode(fidoData.removePrefix("FIDO:/"), Base64.DEFAULT))

            val request = GetCredentialRequest(
                listOf(GetPublicKeyCredentialOption(fidoJson))
            )

            val credentialManager = CredentialManager.create(context)

            MainScope().launch {
                try {
                    val result: GetCredentialResponse = credentialManager.getCredential(
                        request = request,
                        context = activity
                    )

                    val credential = result.credential
                    if (credential is PublicKeyCredential) {
                        onSuccess(credential.authenticationResponseJson)
                    } else {
                        onError("Credential bukan passkey")
                    }
                } catch (e: Exception) {
                    onError("Gagal login: ${e.localizedMessage}")
                }
            }
        } catch (e: Exception) {
            onError("Format FIDO invalid: ${e.localizedMessage}")
        }
    }
}
