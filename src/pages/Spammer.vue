<template>
  <div class="container">
    <base-input :label="`RPC`" placeholder="RPC" @change="changeNode" v-model="currentChosenRPC"></base-input>

    <div>
      <h5>{{ token.name }} {{ token.name ? '/ ' : '' }} {{ token.symbol }}</h5>
      <h5>{{ token.totalSupply ? `total supply: ${token.totalSupply}` : '' }}</h5>
      <h5>{{ token.decimals ? `decimals: ${token.decimals}` : '' }} </h5>
    </div>

    <base-input :label="`token address`" placeholder="token address" @click="pasteContract" v-model="token_address">

    </base-input>

    <div class="row d-flex align-items-center my-3">
      <div class="col-3">
        <base-input :label="`Max TX`" placeholder="Max TX" v-model="max_tx" @change="changeMaxTxTokens"></base-input>
      </div>
      <div class="col-2">
        <base-input :label="`GWEI extra`" placeholder="GWEI" v-model="gweiUsed"></base-input>
        <base-input :label="`Gas Limit`" placeholder="GAS LIMIT" v-model="gasLimitUsed"></base-input>
      </div>
      <div class="col-2">
        <base-input step="0.1" type="number" :label="`ETH value`" placeholder="eth value"
          v-model="eth_value"></base-input>
      </div>
      <div class="col-2">
        <base-input step="0.1" type="number" :label="`TIP value`" placeholder="tip value" v-model="tip"></base-input>
      </div>
      <div class="col-2">
        <base-input type="number" min="0" :label="`token % `" placeholder="token %" v-model="max_tx_percent"
          @change="changeMaxTxPercent">
        </base-input>
      </div>
    </div>


    <div class="easyswapcontainer d-flex align-items-center my-3 row" v-if="recipients.length > 0">
      <small class="text-success">{{ recipients_address }}</small>
      <div class="col-12" v-for="(r, i) in recipients" :key="i" :label="`recipient ${i + 1}`">
        <div class="row d-flex align-items-center">
          <div class="col-1">
            <label for="">{{ r.name }}</label>
          </div>
          <div class="col-10">
            <base-input v-model="r.address" disabled></base-input>
          </div>
          <div class="col-1">
            <base-input type="checkbox" @change="addRemoveWallet(r.address)" style="width='50%'"
              v-if="i != 0"></base-input>

          </div>
        </div>
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

    <div class="row mt-5 d-flex align-items-center">
      <div class="col-9 col-sm-4 d-flex align-items-center">
        <base-button type="primary" @click="startSpamming">start spamming</base-button>
        <base-button type="primary" @click="stopInterval" v-if="intervalID != -1">stop</base-button>
      </div>
      <div class="col-3 col-sm-2 ">
        <base-input type="checkbox" :checked="flat" @change="toggleFlat" :label="flat ? 'flat':'max'"></base-input>
      </div>
      <div class="col-12 col-sm-6">
        <textarea v-model="infoText" name="" id="" rows="10"
          style="width: 100%; background-color: black; color: limegreen;"></textarea>
      </div>


    </div>
  </div>
</template>
<script>
import Web3 from "web3";
import TokenABI from "@/ABIS/Token.json";
import UniswapABI from "@/ABIS/UniswapABI.json"
import SPAM_ABI from "@/ABIS/SpammiosABI.json"
import SPAM_ABI2 from "@/ABIS/Spammios2ABI.json"

import loading from "@/pages/custom_components/loading.vue";
import { ethers, BigNumber } from "ethers";

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
      tip: 0,
      infoText: "",
      eth_value: 0,
      web3: null,
      httpsProvider: null,
      intervalID: -1,
      currentBlock: 0,
      transactionsSent: 0,
      gweiUsed: 20,
      currentGwei: 0,
      gasLimitUsed: 1000000,
      enc: "",
      max_tx_percent: "",
      max_tx: "",
      token: {},
      token_address: "",
      recipients: [],
      recipients_address: [],
      weth_address: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
      uniswapRouterAddress: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
      spammiosAddress: "0xE61053A500877a8F26673CBd548A1F35EcC8ac08",
      spammiosAddress2: "0x0C31fb3ef0155ECA0d4030fe72DA9e1462857FB2",
      wallet: null,
      currentChosenRPC: "",
      flat: false,
      txStatus:-1,
      txWait: false,
    }
  },
  computed: {},
  methods: {
    stopInterval() {
      clearInterval(this.intervalID);
      this.intervalID = -1;
      this.danger("spamming stopped")
      this.txStatus = -1;
      this.txWait = false;
    },
    async startSpamming() {
      return await new Promise(resolve => {
        this.intervalID = setInterval(() => {
          if(this.txWait == false){
            this.checkBlockAndSendTx()
          }

        }, 2000);
      });

      // this.intervalID = setInterval(this.checkBlockAndSendTx(), 2000);
    },
    toggleFlat(){
      this.flat = !this.flat;
      console.log("flat", this.flat)
      this.info(`now using ${this.flat ? 'flat with min token amount, put 0 for slip 100%': 'get max tx'}`)
    },
    async refreshGas() {
      this.currentGwei = 0;
      this.currentGwei = await this.web3.eth.getGasPrice();
      console.log(this.currentGwei)
    },
    addRemoveWallet(address) {
      for (let i = 0; i < this.recipients_address.length; i++) {
        if (this.recipients_address[i] == this.web3.utils.toChecksumAddress(address)) {
          this.recipients_address.splice(i, 1);
          this.danger("removed " + address)
          return;
        }
      }
      this.recipients_address.push(this.web3.utils.toChecksumAddress(address))
      this.success("added " + address)
    },

    async prpepareRawTxData() {
      var contract = new this.web3.eth.Contract(SPAM_ABI2, this.web3.utils.toChecksumAddress(this.spammiosAddress2), { from: this.web3.utils.toChecksumAddress(this.recipients[0].address) });
      var ethAmountToBuyWith = BigNumber.from(this.web3.utils.toWei(`${Number(this.eth_value) + Number(this.tip)}`, 'ether'));
      let tipAmount = BigNumber.from(this.web3.utils.toWei(`${this.tip}`, 'ether'));
      ethAmountToBuyWith = BigNumber.from(ethAmountToBuyWith);
      console.log(ethAmountToBuyWith)
      let maxTxTokens = BigNumber.from(Number(this.max_tx)).mul(BigNumber.from(10).pow(BigNumber.from(this.token.decimals)))
      let path = [this.web3.utils.toChecksumAddress(this.weth_address), this.web3.utils.toChecksumAddress(this.token_address)]

      var data = contract.methods.BuyMany(maxTxTokens._hex, path, this.recipients_address, tipAmount._hex);
      var count = await this.getCurrentNonce(this.web3.utils.toChecksumAddress(this.recipients[0].address));
      console.log(count)
      await this.refreshGas()
      var rawTransaction = {
        "from": this.recipients[0].address,
        "maxFeePerGas": ((BigNumber.from(this.web3.utils.toHex(Number(this.currentGwei))).add(BigNumber.from(Number(this.web3.utils.toWei(`${this.gweiUsed}`, 'gwei'))))))._hex,
        "maxPriorityFeePerGas": ((BigNumber.from(this.web3.utils.toHex(Number(this.currentGwei))).add(BigNumber.from(Number(this.web3.utils.toWei(`${this.gweiUsed}`, 'gwei'))))))._hex,
        "gasLimit": BigNumber.from(this.gasLimitUsed)._hex,
        "to": this.spammiosAddress2,
        "value": ethAmountToBuyWith._hex,
        "data": data.encodeABI(),
        "nonce": this.web3.utils.toHex(`${count}`),
        "type": 2,
        "chainId": 1,
      };
      console.log(rawTransaction)
      this.info(`gwei: ${this.gweiUsed}\ngasLimit: ${this.gasLimitUsed}\nvalue: ${this.eth_value} ETH\ntoken amount: ${this.max_tx} \n eth value ${this.eth_value} ETH\n`)
      if(this.txStatus != 1){
        await this.signAndSendEIP1559Transaction(rawTransaction);
      }
    },
    async prpepareRawTxDataForFlat() {
      var contract = new this.web3.eth.Contract(SPAM_ABI2, this.web3.utils.toChecksumAddress(this.spammiosAddress2), { from: this.web3.utils.toChecksumAddress(this.recipients[0].address) });
      var ethAmountToBuyWith = BigNumber.from(this.web3.utils.toWei(`${Number(this.eth_value) + Number(this.tip)}`, 'ether'));
      let tipAmount = BigNumber.from(this.web3.utils.toWei(`${this.tip}`, 'ether'));
      ethAmountToBuyWith = BigNumber.from(ethAmountToBuyWith);
      console.log(ethAmountToBuyWith)
      let minTokens = BigNumber.from(Number(this.max_tx)).mul(BigNumber.from(10).pow(BigNumber.from(this.token.decimals)))
      let path = [this.web3.utils.toChecksumAddress(this.weth_address), this.web3.utils.toChecksumAddress(this.token_address)]

      var data = contract.methods.BuyManyFlat(minTokens._hex, path, this.recipients_address, tipAmount._hex);
      var count = await this.getCurrentNonce(this.web3.utils.toChecksumAddress(this.recipients[0].address));
      console.log(count)
      await this.refreshGas()
      var rawTransaction = {
        "from": this.recipients[0].address,
        "maxFeePerGas": ((BigNumber.from(this.web3.utils.toHex(Number(this.currentGwei))).add(BigNumber.from(Number(this.web3.utils.toWei(`${this.gweiUsed}`, 'gwei'))))))._hex,
        "maxPriorityFeePerGas": ((BigNumber.from(this.web3.utils.toHex(Number(this.currentGwei))).add(BigNumber.from(Number(this.web3.utils.toWei(`${this.gweiUsed}`, 'gwei'))))))._hex,
        "gasLimit": BigNumber.from(this.gasLimitUsed)._hex,
        "to": this.spammiosAddress2,
        "value": ethAmountToBuyWith._hex,
        "data": data.encodeABI(),
        "nonce": this.web3.utils.toHex(`${count}`),
        "type": 2,
        "chainId": 1,
      };
      console.log(rawTransaction)
      this.info(`gwei: ${this.gweiUsed}\ngasLimit: ${this.gasLimitUsed}\nvalue: ${this.eth_value} ETH\ntoken amount: ${this.max_tx} \n eth value ${this.eth_value} ETH\n`)
      if(this.txStatus != 1){
        await this.signAndSendEIP1559Transaction(rawTransaction);
      }
    },

    async checkBlockAndSendTx() {
      let self = this;
      console.log(this.currentBlock)
      this.web3.eth.getBlockNumber(async function (error, curBlk) {
        self.info("newest block is " + curBlk)
        console.log("cheking block " + curBlk)
        if (curBlk > self.currentBlock && self.txStatus != 1) {
          self.info("sending tx for block " + curBlk);
          self.currentBlock = curBlk
          if(self.flat){
            console.log("sending for flat")
            await self.prpepareRawTxDataForFlat();
          }else{
            console.log("sending for max")
            await self.prpepareRawTxData();
          }
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
          this.recipients_address.push(this.recipients[0].address)
          for (let i = 0; i < intern.length; i++) {
            if (i == 0) {
              this.wallet = (new ethers.Wallet(intern[i].private.toString('hex'), this.httpsProvider));
            }
            delete this.recipients[i].private;
          }

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

    async signAndSendEIP1559Transaction(rawTransaction) {
      // to do the flash bot tx check this link https://docs.flashbots.net/flashbots-auction/searchers/advanced/private-transaction
      try {
        const signedTx = await this.wallet.signTransaction(rawTransaction);
        const txHash = ethers.utils.keccak256(signedTx);
        this.info("sending \n" + txHash);

        let tx = await this.httpsProvider.sendTransaction(signedTx);
        this.txWait = true;
        tx.wait().then(receipt => {
          if (receipt.status === 1) {
            this.txStatus = receipt.status;
            this.txWait = false;
            this.stopInterval();
            this.success('Transaction succeeded:', receipt.hash);
            window.open(`https://etherscan.io/tx/${txHash}`, '_blank')

          } else {
            this.txStatus = receipt.status;
            this.txWait = false;
            this.danger('Transaction reverted:', receipt.hash);
          }
        }).catch(error => {
          this.danger("errored");
          console.log('Error:', error);
        });

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
      this.infoText += "\n " + text;

      this.$notify({
        type: "danger",
        timeout: 2000,
        message: text
      });
    },
    success(text) {
      this.infoText += "\n " + text;

      this.$notify({
        type: "success",
        timeout: 2000,
        message: text
      });
    },
    info(text) {
      this.infoText += "\n " + text;
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

    changeNode() {
      this.web3 = new Web3(this.currentChosenRPC);
      this.httpsProvider = new ethers.providers.JsonRpcProvider(this.currentChosenRPC);
      localStorage.setItem("rpc", this.currentChosenRPC);

    },

  },
  mounted() {
    let publicNode;
    if (localStorage.getItem("rpc")) {
      publicNode = localStorage.getItem("rpc");
      this.currentChosenRPC = localStorage.getItem("rpc");
    } else {
      publicNode = "https://eth.drpc.org";
      this.currentChosenRPC = publicNode
    }
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
