<template>
  <div class="container">
    <div class="row">
        <div class="col">
          <base-input :label="`RPC`" placeholder="RPC" @change="changerpc()" v-model="chosenRpc"></base-input>

        </div>
      </div>

    <div class="row mb-5" v-if="infoText">
      
      <div class="col">
        <textarea name="" id="" v-model="infoText" rows="10" cols="80" style="color: green; background-color: black;"
          readonly></textarea>
      </div>

      <div class="col" v-if="token.name">
        <h5>{{ token.name }} / {{ token.symbol }}</h5>
        <h5>total supply: {{ token.totalSupply }}</h5>
        <h5>decimals: {{ token.decimals }} </h5>
      </div>
    </div>

    <base-input :label="`token address`" placeholder="token address" @click="pasteContract" v-model="token_address">

    </base-input>

    <div class="row d-flex align-items-center my-3">
      <div class="col-2">
        <base-input :label="`Eth Value`" placeholder="1 ETH" v-model="eth_value"></base-input>
        <base-input :label="`Slippage %`" placeholder="20" v-model="slippage"></base-input>
      </div>
      <div class="col-3">
        <!-- <base-input :label="`Max TX`" placeholder="Max TX" v-model="max_tx" @change="changeMaxTxTokens"></base-input> -->
        <base-input :label="`GWEI`" type="number" placeholder="gwei" v-model="gweiUsed"></base-input>
      </div>

      <div class="col-4">
        <base-input label="Method ID or IDs seperated by ," name="method ids" placeholder="Method ids seperated by ,"
          type="text" v-model="chosenMethods"></base-input>

      </div>
      <div class="col-3">
        <!-- <base-input type="number" min="0" :label="`token % `" placeholder="token %" v-model="max_tx_percent"
          @change="changeMaxTxPercent" v-if="token.name">
        </base-input> -->
      </div>
    </div>



    <div class="easyswapcontainer d-flex align-items-center my-3 row" v-if="recipients.length > 0">
      <div class="col-12" v-for="(r, i) in recipients" :key="i" :label="`recipient ${i + 1}`">
        <label for="">{{ r.name }}</label><base-input v-model="r.address" disabled></base-input>
        <!--<input type="checkbox" id="scales" name="scales" @change="addRemoveWallet(r.name, r.address,wallets[i])" :checked="walletsToUse[i].address == r.address" />-->
      </div>
    </div>



    <div class="row" v-if="recipients.length == 0">
      <h5 class="col-12">import wallets to snipe from</h5>
      <div class="row">
        <base-input type="password" name="paswal" class="ml-4" v-model="enc" placeholder="password"></base-input>
        <input type="file" @change="tryImportWallets" class="form mx-5 mt-2" accept="application/JSON"
          style="width: 120px; font-size: 10px;" v-if="recipients.length == 0" />
      </div>
    </div>

    <div class="row mt-5">
      <!-- <base-button type="primary" @click="startScaning" :disabled="!token.name">start scaning</base-button> -->
      <base-button type="primary" @click="apeEth" :disabled="!token.name">Ape ETH</base-button>
      <!-- <base-button type="primary" @click="swapEthForExactTokens" :disabled="!token.name">Ape Max</base-button> -->
      <!-- <base-button type="primary" @click="stopInterval" v-if="intervalID != -1">stop</base-button> -->


    </div>
  </div>
</template>
<script>
import VistaFactoryABI from "@/ABIS/VistaFactoryABI.json"
import VISTA_LP_ABI from "@/ABIS/Vista_LP_ABI.json"
import Web3 from "web3";
import TokenABI from "@/ABIS/Token.json";
import VistaRouter from "@/ABIS/VistaRouter.json"

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
      chosenRpc: "",
      walletsToUse: [],
      infoText: "",
      eth_value: "",
      chosenMethods: "",
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
      vistaRouterAddress: "0xEAaa41cB2a64B11FE761D41E747c032CdD60CaCE",
      vistaFactoryAddress:"0x9a27cb5ae0B2cEe0bb71f9A85C0D60f3920757B4",
      slippage: 30,
      gweiUsed: 5,
      wallets: [],
    }
  },
  computed: {},
  methods: {
    changerpc() {
      if (this.chosenRpc != "") {
        this.web3 = new Web3(this.chosenRpc);
        this.httpsProvider = new ethers.providers.JsonRpcProvider(this.chosenRpc);
        this.info(`using ${this.chosenRpc}`)
        document.cookie = `rpc=${this.chosenRpc}`
      }
    },
    stopInterval() {
      clearInterval(this.intervalID);
      this.intervalID = -1
    },
    addRemoveWallet(name, address, walletProv) {
      let targetIndex = -1;
      for (let i = 0; i < this.walletsToUse.length; i++) {
        if (this.walletsToUse[i].address == address) {
          targetIndex = i;
          break;
        }
      }
      this.walletsToUse.splice(targetIndex, 1);
      console.log(this.walletsToUse)
    },
    async getAmountsOut() {
      var amountToBuyWith = this.web3.utils.toWei(`${Number(this.eth_value)}`, 'ether');
      console.log(amountToBuyWith)
      amountToBuyWith = BigNumber.from(amountToBuyWith)
      let contract = new this.web3.eth.Contract(VistaRouter, this.vistaRouterAddress);
      let result = await contract.methods.getAmountsOut(amountToBuyWith._hex, [this.weth_address, this.token_address]).call();
      console.log(result)
      return result;
    },

    async apeEth() {
      let v_factory = new this.web3.eth.Contract(VistaFactoryABI, this.vistaFactoryAddress);
      let pair = await v_factory.methods.getPair(this.weth_address, this.token_address).call()
      let pair_contract = new this.web3.eth.Contract(VISTA_LP_ABI, pair);
      let buyTotalFee = await pair_contract.methods.buyTotalFee().call()
      console.log("buy total fees ", buyTotalFee)

     
      var tokenAddress = this.token_address; // ONLYONE contract address
      let amountMin;
      if (this.slippage < 100) {
        let x = await this.getAmountsOut();
        console.log(x)
        // slipp normal
        amountMin = BigNumber.from(x[1]).sub((BigNumber.from(x[1])).mul(BigNumber.from(BigNumber.from(this.slippage).div(100))));
        this.info(`youre okay to get ${BigNumber.from(amountMin).div(BigNumber.from(10).pow(this.token.decimals))} tokens instead of ${BigNumber.from(x[1])} tokens due to slippage ${this.slippage}%`)
      } else {
        amountMin = BigNumber.from(0);
        this.info(`Warning your slippage is 100 you're okay to get 0 tokens`);
      }
      console.log(amountMin)
      var contract = new this.web3.eth.Contract(VistaRouter, this.web3.utils.toChecksumAddress(this.vistaRouterAddress), { from: this.web3.utils.toChecksumAddress(this.recipients[0].address) });
      let buyFee = await contract.methods.usdcToEth(buyTotalFee).call();
      console.log(buyFee, this.web3.utils.fromWei(buyFee, 'ether'));

      var amountToBuyWith = this.web3.utils.toWei((Number(this.eth_value) + Number(this.web3.utils.fromWei(buyFee, 'ether'))).toString(), 'ether');

      amountToBuyWith = BigNumber.from(amountToBuyWith);
      console.log(amountToBuyWith)

      var data = contract.methods.swapExactETHForTokensSupportingFeeOnTransferTokens(amountMin._hex, [this.web3.utils.toChecksumAddress(this.weth_address), this.web3.utils.toChecksumAddress(tokenAddress)], this.web3.utils.toChecksumAddress(this.recipients[0].address), this.web3.utils.toHex(Math.round(Date.now() / 1000) + 60 * 20));
      var count = await this.getCurrentNonce(this.web3.utils.toChecksumAddress(this.recipients[0].address));
      console.log(count)
      var rawTransaction = {
        "from": this.recipients[0].address,
        "maxFeePerGas": this.web3.utils.toHex(this.web3.utils.toWei(this.gweiUsed, 'gwei')),
        "maxPriorityFeePerGas": this.web3.utils.toHex(this.web3.utils.toWei(this.gweiUsed, 'gwei')),
        "gasLimit": this.web3.utils.toHex(750000),
        "to": this.vistaRouterAddress,
        "value": amountToBuyWith._hex,
        "data": data.encodeABI(),
        "nonce": this.web3.utils.toHex(`${count}`)
      };
      this.info(`gwei: ${this.gweiUsed}\ngasLimit: ${750000}\nvalue: ${this.eth_value} ETH\ntoken amount: ${this.max_tx} \n eth value ${this.eth_value} ETH\n`)
      this.info(`sending tx`);
      await this.signAndSendEIP1559Transaction(rawTransaction);

    },
    async signAndSendType0Transaction(rawTransaction) {

      try {
        let tx = rawTransaction;
        tx.chainId = 1;
        const signedTx = await this.wallets[0].signTransaction(rawTransaction);
        const txHash = ethers.utils.keccak256(signedTx);
        this.info(txHash);
        let results = await this.httpsProvider.sendTransaction(signedTx);
        console.log(results)

        this.info("tx mined")
        window.open(`https://www.etherscan.io/tx/${txHash}`, '_blank').focus();

      } catch (e) {
        console.warn(e);
        this.danger(`Tx errored:  ${e.toString()}`);
      }
    },
    async swapEthForExactTokens() {

    },
    async startScaning() {
      let methods;
      if (this.chosenMethods.search(",") >= 0) {
        methods = this.chosenMethods.split(",");
      } else {
        methods = [this.chosenMethods];
      }
      // let methodsToListenTo = this.methodIdToScan.split(",");
      this.printTextToConsole("Scanning for " + methods + " in memepool");
      // let tx = await this.prepareTx()
      let tx = this.chosenTokenAmount == 0 ? await this.prepareLightTx() : await this.prepareFlatLightTx();

      let gasLimit = this.web3.utils.toHex(this.chosenGasLimit);
      if (this.useDevAddress) {
        this.alchemy.ws.on({ method: "alchemy_pendingTransactions", fromAddress: this.devAddress }, (res) => {
          console.log(res)
          let currentMethodId = res.input ? res.input.slice(0, 10) : null;
          for (let i = 0; i < methods.length; i++) {
            const meth = methods[i].toLowerCase();
            if (meth == currentMethodId.toLowerCase()) {
              this.start = Date.now();
              if (this.autoGwei) {
                let rawTransaction = this.buildTrackingLightRawTx(tx, gasLimit, res.gasPrice, res.maxFeePerGas, res.maxPriorityFeePerGas);
                console.log(rawTransaction)
                this.signAndSendEIP1559Transaction(rawTransaction);
              } else {
                let rawTransaction = this.buildCustomGweiLightRawTx(tx, gasLimit, res.gasPrice, res.maxFeePerGas, res.maxPriorityFeePerGas);
                console.log(rawTransaction)
                this.signAndSendType0Transaction(rawTransaction);
              }
              this.alchemy.ws.off();
              return;
            }
          }
          return;
        });
      } else {
        this.alchemy.ws.on({ method: "alchemy_pendingTransactions", toAddress: this.token_address }, (res) => {
          console.log(res);
          let currentMethodId = res.input ? res.input.slice(0, 10) : null;
          for (let i = 0; i < methods.length; i++) {
            const meth = methods[i].toLowerCase();
            if (meth == currentMethodId.toLowerCase()) {
              this.start = Date.now();
              if (this.autoGwei) {
                let rawTransaction = this.buildTrackingLightRawTx(tx, gasLimit, res.gasPrice, res.maxFeePerGas, res.maxPriorityFeePerGas);
                console.log(rawTransaction)
                this.signAndSendEIP1559Transaction(rawTransaction);
              } else {
                let rawTransaction = this.buildCustomGweiLightRawTx(tx, gasLimit, res.gasPrice, res.maxFeePerGas, res.maxPriorityFeePerGas);
                console.log(rawTransaction)
                this.signAndSendType0Transaction(rawTransaction);
              }
              this.alchemy.ws.off();
              return;
            }
          }
          return;
        });
      }
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
          for (let i = 0; i < intern.length; i++) {
            this.wallets.push(new ethers.Wallet(intern[i].private.toString('hex'), this.httpsProvider));
            this.walletsToUse.push({ name: this.recipients[i].name, address: this.recipients[i].address, wallet: this.wallets[i] })
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
    async getMaxTxPrice() {
      try {
        var contract = new this.web3.eth.Contract(TokenABI, this.token_address)
        let tokensWithDecimals = BigNumber.from(this.max_tx).mul(BigNumber.from(BigNumber.from(10).pow(this.token.decimals)));
        contract = new this.web3.eth.Contract(VistaRouter, this.vistaRouterAddress, { from: this.walletAddress });
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
    async signAndSendEIP1559Transaction(rawTransaction) {
      // to do the flash bot tx check this link https://docs.flashbots.net/flashbots-auction/searchers/advanced/private-transaction
      try {
        let wallet = this.wallets[0]
        let tx = rawTransaction;
        tx.chainId = 1;
        tx.type = 2;
        const signedTx = await wallet.signTransaction(rawTransaction);
        const txHash = ethers.utils.keccak256(signedTx);
        this.info("sending");
        let x = await this.httpsProvider.sendTransaction(signedTx);
        console.log(x)
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
      let nonce = await this.web3.eth.getTransactionCount(address);
      return nonce;
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
      return this.walletAddress;
    },

  },
  mounted() {
    let publicNode = "https://eth.meowrpc.com";
    this.chosenRpc = publicNode
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
