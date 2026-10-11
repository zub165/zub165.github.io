/**
 * Fill in YOUR PayPal details, then redeploy: DEPLOY_WEB_APP=1 ./website/deploy-web.sh
 *
 * What to send / paste here (any ONE of the payment options is enough):
 * 1) paypalMeUrl  — e.g. https://paypal.me/YourName/4.99  (PayPal app → Profile → PayPal.Me)
 * 2) hostedButtonId — from paypal.com/buttons (Buy Now / Pay Now button)
 * 3) clientId — from developer.paypal.com (Apps & Credentials → Live Client ID) for on-page Smart Buttons
 *
 * unlockCodes: codes you email to buyers after you see the PayPal payment
 *   (static GitHub Pages cannot secretly verify PayPal by itself).
 */
window.ADHAN_PAYPAL = {
  appName: 'Adhan App (Web)',
  priceLabel: '$4.99 USD',
  currency: 'USD',
  amount: '4.99',

  // --- put your real link here ---
  paypalMeUrl: '', // example: 'https://paypal.me/InnovatorsGeneration/4.99'

  hostedButtonId: '', // optional PayPal hosted button id
  clientId: '', // optional Live Client ID for Smart Payment Buttons

  unlockCodes: [
    'ADHAN-WEB-ACCESS', // change this after first deploy
  ],

  contactEmail: 'zub165@yahoo.com',
  storageKey: 'adhan_web_paid_v1',
  appPath: '/adhan/app/',
};
