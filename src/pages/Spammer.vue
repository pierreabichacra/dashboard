<template>
  <div class="container">
    <div v-if="token.name">
      <h5>{{ token.name }} / {{ token.symbol }}</h5>
      <h5>total supply: {{ token.totalSupply }}</h5>
      <h5>decimals: {{ token.decimals }} </h5>
    </div>

    <base-input :label="`token address`" placeholder="token address" @click="pasteContract" v-model="token_address">

    </base-input>

    <div class="row d-flex align-items-center my-3">
      <div class="col-5">
        <base-input :label="`Max TX`" placeholder="Max TX" v-model="max_tx" @change="changeMaxTxTokens"></base-input>
      </div>
      <div class="col-2">
      </div>
      <div class="col-2">
        {{ valueEth }} ETH
      </div>
      <div class="col-3">
        <base-input type="number" min="0" :label="`token % `" placeholder="token %" v-model="max_tx_percent"
          @change="changeMaxTxPercent">
        </base-input>
      </div>
    </div>


    <div class="easyswapcontainer d-flex align-items-center my-3 row" v-if="recipients.length > 0">
      <div class="col-12" v-for="(r, i) in recipients" :key="i" :label="`recipient ${i + 1}`">
        <label for="">{{ r.name }}</label><base-input v-model="r.address" disabled></base-input>
      </div>
    </div>



    <div class="row" v-if="recipients.length == 0">
      <p class="col-12">name address priv</p>
      <div class="row">
        <input type="password" v-model="enc" placeholder="password">
        <label for="" class="mr-5">import wallets to snipe from</label> <input type="file" @change="tryImportWallets"
          class="form" accept="application/JSON" style="width: 120px; font-size: 10px;" v-if="recipients.length == 0" />

      </div>
    </div>

    <div class="row mt-5">
      <base-button type="primary" @click="startSpamming">start spamming</base-button>
      <base-button type="primary" @click="stopInterval" v-if="intervalID != -1">stop</base-button>


    </div>
  </div>
</template>
<script>
import Web3 from "web3";
import TokenABI from "@/ABIS/Token.json";
import UniswapABI from "@/ABIS/UniswapABI.json"

import loading from "@/pages/custom_components/loading.vue";
import { ethers, BigNumber, providers, Transaction, FixedNumber } from "ethers";

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
      web3: null,
      httpsProvider: null,
      intervalID: -1,
      currentBlock: 0,
      transactionsSent: 0,
      enc: "",
      max_tx_percent: "",
      max_tx: "",
      valueEth: 0,
      token: {},
      token_address: "",
      recipients: [],
      weth_address: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
      uniswapRouterAddress: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
    }
  },
  computed: {},
  methods: {
    stopInterval() {
      clearInterval(this.intervalID);
      this.intervalID = -1
    },
    async startSpamming() {
      return await new Promise(resolve => {
        this.intervalID = setInterval(() => {
          this.checkBlockAndSendTx()

        }, 2000);
      });

      // this.intervalID = setInterval(this.checkBlockAndSendTx(), 2000);
    },
    
    async checkBlockAndSendTx() {
      let self = this;
      console.log(this.currentBlock)
      this.web3.eth.getBlockNumber(function (error, curBlk) {
        self.info("newest block is " + curBlk)
        console.log("cheking block " + curBlk)
        if (curBlk > self.currentBlock) {
          self.info("sending tx for block " + curBlk);
          for (let i = 0; i < self.recipients.length; i++) {
            self.success(`tx sent for ${self.recipients[i].name}`);
          }
          self.currentBlock = curBlk
          return curBlk
        }
      });
    },

    async tryImportWallets(e) {
      console.log("try import")
      let file_to_read = e.target.files[0];
      var fileread = new FileReader();
      fileread.onload = (e) => {
        try {
          var content = e.target.result;
          const decryptedText = this.$CryptoJS.AES.decrypt(content, "_1_" + this.enc).toString(this.$CryptoJS.enc.Utf8)
          var intern = JSON.parse(decryptedText); // Array of Objects.
          this.recipients = intern;
        } catch (e) {
          console.error(e)
          this.$notify({
            type: "danger",
            timeout: 1500,
            message: "your files are encrypted a password is needed to import them"
          });
          setTimeout(() => {
            window.location.reload();
          }, 1500);
        }
      };
      fileread.readAsText(file_to_read);

    },
    async getMaxTxPrice() {
      try {
        var contract = new this.web3.eth.Contract(TokenABI, this.token_address)
        let tokensWithDecimals = BigNumber.from(this.max_tx).mul(BigNumber.from(BigNumber.from(10).pow(this.token.decimals)));
        contract = new this.web3.eth.Contract(UniswapABI, this.uniswapRouterAddress, { from: this.walletAddress });
        let value_in_eth = await contract.methods.getAmountsOut(
          tokensWithDecimals,
          [this.token_address, this.weth_address]
        ).call();
        tokensWithDecimals = value_in_eth.length >= 0 ? value_in_eth[1] : 0;
        console.log(ethers.utils.formatEther(value_in_eth[1]))
        this.valueEth = ethers.utils.formatEther(value_in_eth[1]);
      } catch (e) {
        console.error(e)
        this.$notify({
          type: "danger",
          timeout: 1500,
          message: e.toString()
        });
        this.valueEth = "error"
        return 0;
      }
    },
    async pasteContract() {
      this.token_address = await navigator.clipboard.readText();
      await this.getContractInfo();

    },
    changeMaxTxPercent() {
      console.log(this.max_tx_percent)
      if (!this.token.name) {
        return
      }
      this.max_tx = this.token.totalSupply * this.max_tx_percent / 100;
      this.getMaxTxPrice();
    },
    changeMaxTxTokens() {
      this.max_tx_percent = 0;
    },
    async getContractInfo() {
      try {
        let contract = new this.web3.eth.Contract(TokenABI, this.token_address);
        let name = await contract.methods.name().call();
        let symbol = await contract.methods.symbol().call();
        let decimals = await contract.methods.decimals().call();
        let totalSupply = await contract.methods.totalSupply().call();
        this.token = {
          name: name,
          symbol: symbol,
          decimals: decimals,
          totalSupply: totalSupply / Math.pow(10, decimals),
          totalSupplyWithDecimals: totalSupply
        }
      } catch (e) {
        console.warn(e.toString())
        this.$notify({
          type: "danger",
          timeout: 1500,
          message: e.toString()
        });
      }
    },
    addRecipients() {
      this.recipients.push("")
    },
    async signAndSendEIP1559Transaction(rawTransaction, priv) {
      // to do the flash bot tx check this link https://docs.flashbots.net/flashbots-auction/searchers/advanced/private-transaction
      try {
        let wallet = new ethers.Wallet(priv.toString('hex'), this.httpsProvider);
        let tx = rawTransaction;
        tx.chainId = 1;
        tx.type = 2;
        const signedTx = await wallet.signTransaction(rawTransaction);
        const txHash = ethers.utils.keccak256(signedTx);
        this.info("sending");
        let x = await this.httpsProvider.sendTransaction(signedTx);
        window.open(`https://etherscan.io/tx/${txHash}`, '_blank')
        this.success("tx mined");
      } catch (e) {
        console.warn(e);
        this.danger(`Tx erored:  ${e.message}`);
      }
    },
    async sendTx(from, gasLimit, gasPrice, to, value, data, priv) {
      let contract = this.web3.eth.Contract(DumBotABI, this.dumbotAddress, { from: this.walletAddress });
      var data = contract.methods.DumpnBuyRepeat(amountMin._hex, [this.weth_address, this.token_address]);

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
    success(text) {
      this.$notify({
        type: "success",
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
    let publicNode = "https://rpc.mevblocker.io/noreverts";
    this.web3 = new Web3(publicNode);
    this.httpsProvider = new ethers.providers.JsonRpcProvider(publicNode);
    this.info(`using ${publicNode}`)
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
