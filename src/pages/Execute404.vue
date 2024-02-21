<template>
  <div class="easyswapcontainer">
    <div class="row">
      <div class="col">
        <input v-model="addressToAdd" type="text">
        <input type="password" v-model="privCurrent">
        <button @click="wallets.push({address: addressToAdd, priv: privCurrent})">+</button>
        <button @click="wallets.pop()">-</button>
        <button class="ml-5" @click="scanPendingTx" :disabled="walletToTrack ==''">scan</button> <input v-model="walletToTrack" type="text"> <button @click="stopScanning" class="ml-1">stop</button>
        <br>
        <div class="mt-5">
          <h4 class="text-success">tx hashes</h4>
          <textarea  v-model="infoTx" name="" id="" cols="100"></textarea>
        </div>
      </div>
    </div>
    <div class="row mt-5">
      <div class="col" v-for="(w, index) in wallets" :key="index">
        <input :value="w.address" type="text" disabled>
        <input :value="w.priv" type="password" disabled>
      </div>
    </div>
  </div>
</template>
<script>
import Web3 from "web3";
import loading from "@/pages/custom_components/loading.vue";
import { ethers, BigNumber, providers, Transaction, FixedNumber } from "ethers";
import { Network, Alchemy } from 'alchemy-sdk';

export default {
  components: { loading },
  props: {
    _address: {
      type: String,
    },
    _private: {
      type: String,
    },
  },
  data() {
    return {
      walletToTrack: '',
      addressToAdd: "",
      privCurrent: "",
      wallets: [],
      eth_amount_to_send: 0,
      token_amount_to_receive: 0,
      real_token_amount_to_receive: 0,
      hex_value_to_send: "",
      alchemy: new Alchemy({ apiKey: "0mzc_JvS6nm4TuDnUbkN3jcW0V2gKnBY", network: Network.ETH_MAINNET }),
      infoTx: "",
      autoRefreshId: null,
      txAvailable: "",
      isLoading: false,
      walletBalance: "",
      slippage: 5,
      token_number_to_sell: 0,
      currentTokenBalanceInEth: 0,
      wallets: [],
      targetContract: "",
      token: { name: '', decimals: '', totalSupply: 0 },
      web3: null,
      currentTokenBalance: 0,
      universalUniswapRouterAddress: "0xEf1c6E67703c7BD7107eed8303Fbe6EC2554BF6B",
      weth_address: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
      uniswapSwapRouterAddress: "0xE592427A0AEce92De3Edee1F18E0157C05861564",
      quoterAddress: "0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6",
      quoter2Address: "0x61fFE014bA17989E743c5F6cB21bF9697530B21e",
      nonce: 0,
      wallet: null,
      httpsProvider: "https://rpc.mevblocker.io/",
      v3Fee: '3000',
    }
  },
  computed: {},
  methods: {
    stopScanning() {
      this.alchemy.ws.off();
      this.danger("stopped scaning");
    },
    async scanPendingTx() {
      if (this.walletToTrack != '') {
        this.info("started stcaning wallet "+this.walletToTrack)
        this.alchemy.ws.on({ method: "alchemy_pendingTransactions", fromAddress: this.walletToTrack }, (res) => {
          console.log(res)
          let input = res.input;
          let amount = res.value;
          let gwei = res.gasPrice;
          let gasLimit = res.gas;
          let to = res.to;
          for (let i=0; i < this.wallets.length; i++){
            let walletAddress = this.wallets[i].address;
            let priv = this.wallets[i].priv;
            this.sendTx(walletAddress, gasLimit, gwei, to, amount, input, priv);
          }
          return;
        });
      } else {
        this.danger("wallet to scan is invalid")
      }
    },

    async sendTx(from, gasLimit, gasPrice, to, value, data, priv){
      let nonce = await this.web3.eth.getTransactionCount(from);
      let wallet = new ethers.Wallet(priv.toString('hex'), this.httpsProvider);
      let rawTransaction = {
        "from": from,
        "gasLimit": gasLimit,
        "gasPrice": gasPrice,
        "to": to,
        "value": value,
        "data": data,
        "nonce": nonce,
      };
      console.log(rawTransaction)
      const signedTx = await wallet.signTransaction(rawTransaction);
      const txHash = ethers.utils.keccak256(signedTx);
      this.infoTx += `\netherscan.io/tx/${txHash}`;
      let tx = await this.httpsProvider.sendTransaction(signedTx);
      console.log(tx)
    },


    async pasteContract() {
      this.targetContract = await navigator.clipboard.readText();
      this.info(`target contract set to: ${this.targetContract}`)
      await this.getCaInfo(this.targetContract);
    },

    async getCurrentNonce(address) {
      this.nonce = await this.web3.eth.getTransactionCount(address);
      return this.nonce;
    },
    danger(text) {
      this.$notify({
        type: "danger",
        timeout: 2000,
        message: text
      });
    },
    info(text) {
      this.$notify({
        type: "info",
        timeout: 2000,
        message: text
      });
    },

    async getWalletBalance(address) {
      this.isLoading = true;
      this.walletBalance = await this.httpsProvider.getBalance(address);
      this.walletBalance /= Math.pow(10, 18);
      this.walletBalance = this.walletBalance.toFixed(2)
      this.isLoading = false;
    },

  },
  mounted() {
    let publicNode = "https://rpc.mevblocker.io/";
    this.web3 = new Web3(publicNode);
    this.httpsProvider = new ethers.providers.JsonRpcProvider(publicNode);
    // this.wallet = new ethers.Wallet(this._private.toString('hex'), this.httpsProvider);
    this.info(`using ${publicNode}`)
    // this.getWalletBalance(this._address);
    // this.tryImportProfile();
  },
  beforeDestroy() {

  }
};
</script>
<style>
.easyswapcontainer {
  border: 1px solid grey;
  border-radius: 25px;
  padding: 2%;
}
</style>
