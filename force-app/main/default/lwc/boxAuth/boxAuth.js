import { LightningElement } from 'lwc';
import getBoxLoginUrl from '@salesforce/apex/BoxAuthController.getBoxLoginUrl';
import exchangeCodeForToken from '@salesforce/apex/BoxAuthController.exchangeCodeForToken';

export default class BoxAuth extends LightningElement {

    connectBox(){

        getBoxLoginUrl()
        .then(url => {

            if(!url){

                this.dispatchEvent(
                    new CustomEvent('autherror',{
                        detail:'Unable to generate Box login URL'
                    })
                );
                return;
            }

            const popup = window.open(
                url,
                "BoxLogin",
                "width=600,height=700"
            );

            if(!popup){

                this.dispatchEvent(
                    new CustomEvent('autherror',{
                        detail:'Popup blocked. Please allow popups'
                    })
                );

            }

        })
        .catch(error=>{

            let message = 'Connection Error';

            if(error.body && error.body.message){
                message = error.body.message;
            }

            this.dispatchEvent(
                new CustomEvent('autherror',{
                    detail:message
                })
            );

        });

    }

    connectedCallback(){

        window.addEventListener("message", (event)=>{

            if(event.data && event.data.type === "BOX_AUTH"){

                const authCode = event.data.code;

                exchangeCodeForToken({authCode : authCode})
                .then(()=>{

                    this.dispatchEvent(
                        new CustomEvent("authsuccess")
                    );

                })
                .catch(error=>{

                    let message = 'Authentication Failed';

                    if(error.body && error.body.message){
                        message = error.body.message;
                    }

                    this.dispatchEvent(
                        new CustomEvent("autherror",{
                            detail:message
                        })
                    );

                });

            }

        });

    }

}