<template>
  <div>
    <div class="row">
      <div class="col-12">
        <card type="first">
          <template slot="header">
            <div class="row">
              <div class="col-sm-12" :class="isRTL ? 'text-right' : 'text-left'">
                <h5 class="card-category">Bots</h5>
                <h2 class="card-title">
                  Magma Beta
                  <span class="text-right">
                    <loading v-if="isLoading" />
                  </span>
                </h2>
              </div>
            </div>
          </template>
          <div class="row d-flex align-items-center">
            <div class="col-10 ">
              <base-input label="Custom Node" placeholder="Custom Node" v-model="customNode">
              </base-input>
            </div>
            <div class="col-2">
              <base-button type="primary" @click="saveCustomNode" fill>save</base-button>
            </div>
          </div>
          <div class="row d-flex align-items-center">

            <div class="col-5 col-sm-3">
              <base-input label="Wallet Address" placeholder="your wallet address" v-model="walletAddress">
              </base-input>
            </div>
            <div class="col-5 col-sm-3">
              <base-input label="Private Key" placeholder="Your private key" type="password" v-model="privateKey"
                @change="attachWallet">
              </base-input>
            </div>
            <div class="col-2 col-sm-6">
              <div class="row">
                <div class="col pt-2">
                  <base-button type="primary" @click="getCurrentGwei" fill>GWEI [ {{ currentGwei }} ]</base-button>
                  <base-button type="success mx-1" @click="getCurrentNonce" fill>Nonce [ {{ nonce }} ]</base-button>
                  <base-button type="danger mx-1" @click="cancelTransaction" fill>Cancel Tx</base-button>
                  <base-button type="success mx-1" @click="giveBackMagmaFunds" fill>Refund</base-button>
                  <base-button type="danger mx-1" @click="stopScanning" fill>stop scanning</base-button>
                </div>
              </div>
            </div>
          </div>
        </card>
        <card type="chart">

          <div class="row d-flex align-items-center">
            <div class="col-12 col-sm-8">

              <div class="row">
                <div class="col-12 col-sm-12 d-flex felx-row">
                  <base-button type="warning mx-1" @click="checkPrepareNonce" fill>Nonce Prepared <input type="checkbox"
                      v-model="noncePrepared" readonly></base-button>
                  <base-button type="warning mx-1" @click="checkAutoGwei" fill>Auto Gwei <input type="checkbox"
                      v-model="autoGwei" readonly></base-button>
                  <base-button type="warning mx-1" @click="checkFlashTX" fill>Flash TX <input type="checkbox"
                      v-model="flashTx" readonly></base-button>

                </div>
                <div class="col-12 col-sm-12 d-flex felx-row">
                  <base-input style="width: 97%;" :label="`Dev Address ${useDevAddress ? 'USING DEV ADDRESS' : ''}`"
                    placeholder="Dev Address" type="text" v-model="devAddress">
                  </base-input> <input type="checkbox" class="mx-2 mt-2" name="userDev" v-model="useDevAddress" id="">
                </div>
                <div class="col-12 col-sm-6">
                  <div class="col-6 col-sm-6">
                    <base-input label="GWEI" type="number" placeholder="gwei" @change="changeChosenGwei"
                      v-model="chosenGwei">
                    </base-input>
                  </div>
                  <div class="col-6 col-sm-6">
                    <base-input label="Gas Limit" placeholder="gas limit" type="number" v-model="chosenGasLimit">
                    </base-input>
                    <base-input label="Slippage (%)" placeholder="slippage" type="number" v-model="slippage">
                    </base-input>
                  </div>
                </div>
                <div class="col-12 col-sm-6">
                  <div class="col-6 col-sm-6">
                    <base-input label="Eth Investment" type="number" step="0.01" placeholder="eth amount"
                      v-model="chosenEthValue">
                    </base-input>
                  </div>
                  <div class="col-6 col-sm-6">
                    <base-input label="Token Amount" placeholder="token amount" type="number" v-model="chosenTokenAmount">
                    </base-input>

                    <base-input label="Method ID" placeholder="Method id" type="text" v-model="chosenMethods">
                    </base-input>
                  </div>
                </div>
                <div class="col-12 col-sm-12 px-4">
                  <base-input label="Contract" placeholder="Contract" type="text" v-model="targetContract"
                    @click="pasteContract"></base-input>
                  <base-button type="warning mx-1" @click="scanPendingTx" fill>Scan</base-button>
                  <base-button type="primary mx-1" @click="sendLightTransaction" fill>swap eth for exact
                    tokens</base-button>
                  <base-button type="primary mx-1" @click="sendFlatBuy" fill>Flat Buy</base-button>

                </div>
              </div>
            </div>
            <div class="col-12 col-sm-4">
              <h4 class="text-center" v-if="token">{{ token.name }} ({{ token.symbol }}) [{{ token.decimals }} decimals]
                {{ token.totalSupply }}
              </h4>
              <div class="row d-flex align-items-center ml-5">
                <base-input label="token percentage" style="width: 25%" placeholder="1%" type="number"
                  v-model="tokenPercentage"></base-input><br />
                <base-button type="secondary mx-1 mt-3" style="height: 40px" @click="getPercOfToken" fill>%</base-button>
                {{ tokenAmountToCopy }}
              </div>

              <div id="console" v-html="consoleText"
                style="height: 30vh; background-color: black; overflow-y: scroll; color: white; padding: 10px 10px 10px 20px;">
              </div>
            </div>
          </div>
        </card>
        <div class="row">
          <div class="col">
            <card type="info">
              info about wallet <small class="text-warning">file extension should be in json</small>
              <p>
                the file to import should look like this <span class="text-success"> [{"name": "wallet 1", "address":
                  "0xaef034f...", "private": "0xaef43efbcd4..."}]</span><br>
                for 2 wallets and more:<br>
                <span class="text-success">
                  [
                  <br>{"name": "wallet 1", "address": "0xaef034f...", "private": "0xaef43efbcd4..."},<br> {"name": "wallet
                  2", "address": "0xbef034f...", "private": "0xbef43efbcd4..."},
                  <br> ...and so on for more wallets
                  <br>
                  ]
                </span>
              </p>
            </card>
          </div>
          <div class="col">
            <card type="info">
              <div class="row">
                <div class="col">
                  <base-button type="secondary mx-1" @click="approveToken" fill>Approve</base-button>
                  <base-button type="danger mx-1" @click="sellAll" fill>Sell All</base-button>
                  <base-button type="warning mx-1" @click="getTokenBalance" fill>Check Balance</base-button>
                  <loading v-if="isLoading" />

                  <base-input label="Token Balance" placeholder="0" type="text"
                    v-model="currentTokenBalance"></base-input>
                  <base-input label="Balance in ETH" placeholder="0" type="text" v-model="tokensValInEth"></base-input>

                </div>
              </div>
            </card>
          </div>
        </div>

      </div>
    </div>
  </div>
</template>
<script>
import Web3 from "web3";
import loading from "@/pages/custom_components/loading.vue";
import TokenAbi from "@/ABIS/Token.json";
import UniswapAbi from "@/ABIS/UniswapABI.json";
import { ethers, BigNumber, providers } from "ethers";
import { Network, Alchemy } from 'alchemy-sdk';
import MagmaABI from "@/ABIS/MagmaNewest.json";
import { FlashbotsBundleProvider } from "@flashbots/ethers-provider-bundle";

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
      nonce: 0,
      currentGwei: 0,
      isLoading: false,
      consoleText: "",

      tokenAmountToCopy: 0,
      tokenPercentage: .5,
      chosenTokenAmount: 0,
      chosenGwei: 30,
      slippage: 100,
      chosenGasLimit: 400000,
      chosenEthValue: 0.01,
      chosenMethods: "",
      devAddress: "",
      targetContract: "",
      useDevAddress: false,
      noncePrepared: false,
      autoGwei: false,
      flashTx: false,

      wallet: null,
      token: null,
      currentTokenBalance: 0,
      currentTokenBalanceInEth: 0,
      actualChosenGwei: 30 * Math.pow(10, 9),

      // defaultNode: "https://eth.llamarpc.com",
      defaultNode: "https://ethereum.publicnode.com",
      httpsProvider: null,
      customNode: "",
      web3: null,

      walletAddress: "",
      privateKey: "",
      walletName: "",
      selectedWallet: -1,

      weth_address: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
      magmaAddress: "0x4Fc3b4EF49c2f92C8402da818DEe8CD71B666054",
      uniswapRouterAddress: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
      alchemy: new Alchemy({ apiKey: "0mzc_JvS6nm4TuDnUbkN3jcW0V2gKnBY", network: Network.ETH_MAINNET }),
      start: Date.now(),
      walletsLoaded: [],
      flashbotsProvider: null,

    }
  },
  computed: {
    enableRTL() {
      return this.$route.query.enableRTL;
    },
    isRTL() {
      return this.$rtl.isRTL;
    },
    tokensValInEth: function () {
      if (this.currentTokenBalanceInEth && this.currentTokenBalanceInEth > 0) {
        let returnable = this.web3.utils.fromWei(this.currentTokenBalanceInEth, 'ether');
        returnable = returnable.toString();
        return returnable;
      } else {
        return 0;
      }
    }
  },
  methods: {
    saveCustomNode() {
      if (this.customNode) {
        localStorage.setItem("customNode", this.customNode);
        this.$notify("custom node saved with rpc " + this.customNode)
      } else {
        localStorage.removeItem("customNode")
        this.$notify(`customNode deleted please refresh to start using the default node ${this.defaultNode}`);
      }
    },
    switchWallet(w) {
      console.log(this.selectedWallet)
      this.walletAddress = this.selectedWallet.address;
      this.privateKey = this.selectedWallet.priv;
      this.walletName = this.selectedWallet.name;
      this.attachNode();
      this.attachWallet();
      console.log("switched");
    },
    stopScanning() {
      this.alchemy.ws.off();
      this.printTextToConsole("stopped scaning");
    },
    async scanPendingTx() {
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
        this.alchemy.ws.on({ method: "alchemy_pendingTransactions", toAddress: this.targetContract }, (res) => {
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

    async prepareFlatLightTx() {
      var amountToBuyWith = this.web3.utils.toWei(`${this.chosenEthValue}`, 'ether');
      amountToBuyWith = BigNumber.from(amountToBuyWith);
      var tokenAddress = this.targetContract; // ONLYONE contract address
      let _amountMint = 0;
      var routerAbi = MagmaABI;
      var contract = new this.web3.eth.Contract(routerAbi, this.magmaAddress, { from: this.walletAddress });
      var data = contract.methods.flatLight(
        _amountMint._hex,
        [this.weth_address, tokenAddress],
      );
      var count = 0;
      if (this.noncePrepared) {
        count = this.nonce;
      } else {
        count = await this.getCurrentNonce();
      }
      var rawTransaction = {
        "from": this.walletAddress,
        // "gasPrice":this.web3.utils.toHex(this.gwei),
        // "gasLimit":this.web3.utils.toHex(this.gasLimit),
        "to": this.magmaAddress,
        "value": amountToBuyWith._hex,
        "data": data.encodeABI(),
        "nonce": this.web3.utils.toHex(count)
      };
      this.printTextToConsole(`gwei: copy\ngasLimit: ${this.chosenGasLimit}\value: ${this.chosenEthValue} ETH\ntoken amount: ${this.chosenTokenAmount}\nwaiting for tx\n`)
      return rawTransaction;
    },

    async prepareLightTx() {
      var amountToBuyWith = this.web3.utils.toWei(`${this.chosenEthValue}`, 'ether');
      amountToBuyWith = BigNumber.from(amountToBuyWith);
      var tokenAddress = this.targetContract; // ONLYONE contract address
      let _amountMint = BigNumber.from(this.chosenTokenAmount).mul(BigNumber.from(BigNumber.from(10).pow(this.token.decimals)));
      var routerAbi = MagmaABI;
      var contract = new this.web3.eth.Contract(routerAbi, this.magmaAddress, { from: this.walletAddress });
      var data = contract.methods.light(
        _amountMint._hex,
        [this.weth_address, tokenAddress],
      );
      var count = 0;
      if (this.noncePrepared) {
        count = this.nonce;
      } else {
        count = await this.getCurrentNonce();
      }
      var rawTransaction = {
        "from": this.walletAddress,
        // "gasPrice":this.web3.utils.toHex(this.gwei),
        // "gasLimit":this.web3.utils.toHex(this.gasLimit),
        "to": this.magmaAddress,
        "value": amountToBuyWith._hex,
        "data": data.encodeABI(),
        "nonce": this.web3.utils.toHex(count)
      };
      this.printTextToConsole(`gwei: copy\ngasLimit: ${this.chosenGasLimit}\value: ${this.chosenEthValue} ETH\ntoken amount: ${this.chosenTokenAmount}\nwaiting for tx\n`)
      return rawTransaction;
    },
    buildTrackingLightRawTx(transaction_raw, gas, gasPrice, maxFeePerGas, maxPriorityFeePerGas) {
      let rawTransaction = {
        "from": transaction_raw.from,
        "gasLimit": gas,
        "maxFeePerGas": this.web3.utils.toHex(maxFeePerGas * 2),
        "maxPriorityFeePerGas": this.web3.utils.toHex(maxPriorityFeePerGas * 2),
        "to": this.magmaAddress,
        "value": transaction_raw.value,
        "data": transaction_raw.data,
        "nonce": transaction_raw.nonce,
      };
      return rawTransaction;
    },
    buildCustomGweiLightRawTx(transaction_raw, gas, gasPrice, maxFeePerGas, maxPriorityFeePerGas) {
      let rawTransaction = {
        "from": transaction_raw.from,
        "gasLimit": gas,
        "gasPrice": this.web3.utils.toHex(this.actualChosenGwei),
        "to": this.magmaAddress,
        "value": transaction_raw.value,
        "data": transaction_raw.data,
        "nonce": transaction_raw.nonce,
      };
      return rawTransaction;
    },
    async sellAll() {
      let token_to_sell = this.targetContract;
      let token_to_receive = "1";
      let token_bal = await this.getTokenBalance();
      let number_of_tokens_to_sell = BigNumber.from(token_bal);
      var contract = new this.web3.eth.Contract(UniswapAbi, this.uniswapRouterAddress, { from: this.walletAddress });
      var data = contract.methods.swapExactTokensForETHSupportingFeeOnTransferTokens(
        number_of_tokens_to_sell._hex,
        this.web3.utils.toHex(token_to_receive),
        [token_to_sell, this.weth_address],
        this.walletAddress,
        this.web3.utils.toHex(Math.round(Date.now() / 1000) + 60 * 20),
      );
      var count = 0;
      if (this.noncePrepared) {
        count = this.nonce;
      } else {
        count = await this.getCurrentNonce();
      }
      var rawTransaction = {
        "from": this.walletAddress,
        "maxFeePerGas": `0x${this.actualChosenGwei.toString(16)}`,
        "maxPriorityFeePerGas": `0x${this.actualChosenGwei.toString(16)}`,
        "gasLimit": this.web3.utils.toHex(this.chosenGasLimit),
        "to": this.uniswapRouterAddress,
        // "value":this.web3.utils.toHex(amountToBuyWith),
        "data": data.encodeABI(),
        "nonce": this.web3.utils.toHex(count)
      };
      console.log(rawTransaction);
      await this.signAndSendEIP1559Transaction(rawTransaction)
    },
    async giveBackMagmaFunds() {
      let start = new Date();
      var routerAbi = MagmaABI;
      var contract = new this.web3.eth.Contract(routerAbi, this.magmaAddress, { from: this.walletAddress });
      var data = contract.methods.giveBack();
      var count = 0;
      if (this.noncePrepared) {
        count = this.nonce;
      } else {
        count = await this.getCurrentNonce();
      }
      var rawTransaction = {
        "from": this.walletAddress,
        "maxFeePerGas": `0x${this.actualChosenGwei.toString(16)}`,
        "maxPriorityFeePerGas": `0x${this.actualChosenGwei.toString(16)}`,
        "gasLimit": this.web3.utils.toHex(this.chosenGasLimit),
        "to": this.magmaAddress,
        // "value": amountToBuyWith._hex,
        "data": data.encodeABI(),
        "nonce": this.web3.utils.toHex(count)
      };
      let end = Date.now();
      this.printTextToConsole(`tx sent in: ${end - start} ms`);
      await this.signAndSendEIP1559Transaction(rawTransaction);
      end = Date.now();
      this.printTextToConsole(`tx mined in: ${end - start} ms`);

    },
    getPercOfToken() {
      this.tokenAmountToCopy = this.token.totalSupply * this.tokenPercentage / 100;
      this.chosenTokenAmount = this.tokenAmountToCopy;
    },
    async sendLightTransaction() {
      const start = Date.now();
      var amountToBuyWith = this.web3.utils.toWei(`${this.chosenEthValue}`, 'ether');
      amountToBuyWith = BigNumber.from(amountToBuyWith);
      var tokenAddress = this.targetContract; // ONLYONE contract address
      let amountMin = BigNumber.from(this.chosenTokenAmount).mul(BigNumber.from(BigNumber.from(10).pow(this.token.decimals)));
      var routerAbi = MagmaABI;
      var contract = new this.web3.eth.Contract(routerAbi, this.magmaAddress, { from: this.walletAddress });
      var data = contract.methods.light(
        amountMin._hex,
        [tokenAddress, this.weth_address],
      );
      var count = 0;
      if (this.noncePrepared) {
        count = this.nonce;
      } else {
        count = await this.getCurrentNonce();
      }
      var rawTransaction = {
        "from": this.walletAddress,
        "maxFeePerGas": `0x${this.actualChosenGwei.toString(16)}`,
        "maxPriorityFeePerGas": `0x${this.actualChosenGwei.toString(16)}`,
        "gasLimit": this.web3.utils.toHex(this.chosenGasLimit),
        "to": this.magmaAddress,
        "value": amountToBuyWith._hex,
        "data": data.encodeABI(),
        "nonce": this.web3.utils.toHex(count)
      };
      this.printTextToConsole(`gwei: ${this.chosenGwei}\ngasLimit: ${this.chosenGasLimit}\nvalue: ${this.chosenEthValue} ETH\ntoken amount: ${this.chosenTokenAmount}\n`)
      let end = Date.now();
      this.printTextToConsole(`tx sent in: ${end - start} ms`);
      await this.signAndSendEIP1559Transaction(rawTransaction);
      end = Date.now();
      this.printTextToConsole(`tx mined in: ${end - start} ms`);
    },



    async sendFlatBuy() {
      const start = Date.now();
      var amountToBuyWith = this.web3.utils.toWei(`${this.chosenEthValue}`, 'ether');
      amountToBuyWith = BigNumber.from(amountToBuyWith);
      var tokenAddress = this.targetContract; // ONLYONE contract address
      let x = await this.getAmountsOut();
      let amountMin;
      if (this.slippage < 100) {
        // slipp normal
        amountMin = (x[1]) - (x[1] * this.slippage / 100);
        this.printTextToConsole(`youre okay to get ${BigNumber.from(amountMin).div(BigNumber.from(10).pow(this.token.decimals))} tokens instead of ${x[1]} tokens sue to slippage ${this.slippage}%`)
      } else {
        amountMin = BigNumber.from(0);
        this.printTextToConsole(`Warning your slippage is 100 you're okay to get 0 tokens`);
      }
      var routerAbi = MagmaABI;
      var contract = new this.web3.eth.Contract(routerAbi, this.magmaAddress, { from: this.walletAddress });
      var data = contract.methods.flatLight(amountMin._hex, [this.weth_address, tokenAddress]);
      var count = 0;
      if (this.noncePrepared) {
        count = this.nonce;
      } else {
        count = await this.getCurrentNonce();
      }
      var rawTransaction = {
        "from": this.walletAddress,
        "gasLimit": this.web3.utils.toHex(this.chosenGasLimit),
        "gasPrice": this.web3.utils.toHex(this.actualChosenGwei),
        "to": this.magmaAddress,
        "value": amountToBuyWith._hex,
        "data": data.encodeABI(),
        "nonce": this.web3.utils.toHex(count)
      };
      this.printTextToConsole(`gwei: ${this.chosenGwei}\ngasLimit: ${this.chosenGasLimit}\nvalue: ${this.chosenEthValue} ETH\ntoken amount: ${this.chosenTokenAmount}\n`)
      let end = Date.now();
      this.printTextToConsole(`tx sent in: ${end - start} ms`);
      await this.signAndSendType0Transaction(rawTransaction);
      end = Date.now();
      this.printTextToConsole(`tx mined in: ${end - start} ms`);

    },

    checkPrepareNonce() {
      this.noncePrepared = !this.noncePrepared;
    },
    checkAutoGwei() {
      this.autoGwei = !this.autoGwei;
    },
    checkFlashTX() {
      this.flashTx = !this.flashTx;
    },
    async getTokenBalance() {
      try {
        this.isLoading = true;
        var contract = new this.web3.eth.Contract(TokenAbi, this.targetContract)
        let result = await contract.methods.balanceOf(this.walletAddress).call();
        this.currentTokenBalance = result;
        contract = new this.web3.eth.Contract(UniswapAbi, this.uniswapRouterAddress, { from: this.walletAddress });
        let value_in_eth = await contract.methods.getAmountsOut(
          this.currentTokenBalance,
          [this.targetContract, this.weth_address]
        ).call();
        this.currentTokenBalanceInEth = value_in_eth.length >= 0 ? value_in_eth[1] : 0;
        this.isLoading = false;
        return result;
      } catch (e) {
        this.printTextToConsole(e.toString())
        this.isLoading = false;
        return 0;
      }

    },
    async getAmountsOut() {
      var amountToBuyWith = this.web3.utils.toWei(`${this.chosenEthValue}`, 'ether');
      amountToBuyWith = BigNumber.from(amountToBuyWith)
      let contract = new this.web3.eth.Contract(UniswapAbi, this.uniswapRouterAddress);
      let result = await contract.methods.getAmountsOut(amountToBuyWith._hex, [this.weth_address, this.targetContract]).call();
      console.log(result);
      return result;
    },

    async pasteContract(e) {
      this.targetContract = await navigator.clipboard.readText();
      this.getCaInfo(this.targetContract);
    },
    async getCaInfo(e) {
      try {
        let ca;
        console.log(e)
        if (e.target) {
          ca = e.target.value;
          this.printTextToConsole(ca)
        } else {
          ca = this.targetContract;
        }

        let contract = new this.web3.eth.Contract(TokenAbi, ca);
        let name = await contract.methods.name().call();
        let symbol = await contract.methods.symbol().call();
        let decimals = await contract.methods.decimals().call();
        let totalSupply = await contract.methods.totalSupply().call();
        this.token = {
          name: name,
          symbol: symbol,
          decimals: decimals,
          totalSupply: totalSupply / Math.pow(10, decimals)
        }
      } catch (e) {
        this.printTextToConsole(e.toString())
      }

    },
    async approveToken() {
      var contract = new this.web3.eth.Contract(TokenAbi, this.targetContract, { from: this.walletAddress });
      let maxAmountToApprove = BigNumber.from(this.token.totalSupply).mul(BigNumber.from(BigNumber.from(10).pow(this.token.decimals)));
      console.log(maxAmountToApprove)
      var data = contract.methods.approve(
        this.uniswapRouterAddress,
        maxAmountToApprove._hex
      );
      var count = 0;
      if (this.noncePrepared) {
        count = this.nonce;
      } else {
        count = await this.getCurrentNonce();
      }
      var rawTransaction = {
        "from": this.walletAddress,
        "maxFeePerGas": `0x${this.actualChosenGwei.toString(16)}`,
        "maxPriorityFeePerGas": `0x${this.actualChosenGwei.toString(16)}`,
        "gasLimit": this.web3.utils.toHex(this.chosenGasLimit),
        "to": this.targetContract,
        "data": data.encodeABI(),
        "nonce": this.web3.utils.toHex(count)
      };
      try {
        this.signAndSendEIP1559Transaction(rawTransaction)
      } catch (e) {
        console.log(e)
        this.printTextToConsole("reverted")
      }

    },
    async signAndSendEIP1559Transaction(rawTransaction) {
      // to do the flash bot tx check this link https://docs.flashbots.net/flashbots-auction/searchers/advanced/private-transaction
      try {
        let tx = rawTransaction;
        tx.chainId = 1;
        tx.type = 2;

        if (this.flashTx) {
          let signer = this.privateKey;
          const res = await this.flashbotsProvider.sendPrivateTransaction({tx, signer}, {maxBlockNumber: (await this.httpsProvider.getBlockNumber()) + 1});
          const waitRes = await res.wait();
          if (waitRes === FlashbotsTransactionResolution.TransactionIncluded) {
            this.printTextToConsole("Private transaction successfully included on-chain.");
          } else if (waitRes === FlashbotsTransactionResolution.TransactionDropped) {
            this.printTextToConsole("Private transaction was not included in a block and has been removed from the system.");
          }
        } else {
          const signedTx = await this.wallet.signTransaction(rawTransaction);
          const txHash = ethers.utils.keccak256(signedTx);
          this.printLinkToConsole(txHash);
          await this.httpsProvider.sendTransaction(signedTx);
          this.printTextToConsole("tx mined");
        }
      } catch (e) {
        console.warn(e);
        this.printTextToConsole(`Tx errored:  ${e.toString()}`);
      }
    },

    async signAndSendType0Transaction(rawTransaction) {

      try {
        let tx = rawTransaction;
        tx.chainId = 1;

        if (this.flashTx) {
          let signer = this.privateKey;
          const res = await this.flashbotsProvider.sendPrivateTransaction({
            tx,
            signer,
          }, {
            maxBlockNumber: (await this.httpsProvider.getBlockNumber()) + 1, // only allow tx to be included for the next 5 blocks
          });

          const waitRes = await res.wait();
          if (waitRes === FlashbotsTransactionResolution.TransactionIncluded) {
            this.printTextToConsole("Private transaction successfully included on-chain.")
          } else if (waitRes === FlashbotsTransactionResolution.TransactionDropped) {
            this.printTextToConsole("Private transaction was not included in a block and has been removed from the system.")
          }
        } else {
          const signedTx = await this.wallet.signTransaction(rawTransaction);
          const txHash = ethers.utils.keccak256(signedTx);
          this.printLinkToConsole(txHash)
          await this.httpsProvider.sendTransaction(signedTx);
        }
        this.printTextToConsole("tx mined")
      } catch (e) {
        console.warn(e);
        this.printTextToConsole(`Tx errored:  ${e.toString()}`);
      }
    },
    printTextToConsole(text) {
      this.consoleText += `<p>${text.replaceAll("\n", "<br/>")}</p>`;
    },
    printLinkToConsole(hash) {
      this.consoleText += `<a href="https://etherscan.io/tx/${hash}" target="_blank"> TX HASH </a>`;
    },
    async getCurrentGwei() {
      this.isLoading = true;
      let gas = await this.web3.eth.getGasPrice();
      this.currentGwei = Math.ceil(gas / Math.pow(10, 9));
      this.isLoading = false;
    },
    changeChosenGwei(e) {
      this.chosenGwei = e.target.value;
      this.actualChosenGwei = this.chosenGwei * Math.pow(10, 9);
      this.printTextToConsole(`GWEI: ${this.actualChosenGwei / Math.pow(10, 9)}`)
    },
    async cancelTransaction() {
      this.isLoading = true;
      let rawTx = {
        nonce: `0x${this.nonce.toString(16)}`,
        maxFeePerGas: `0x${this.actualChosenGwei.toString(16)}`,
        maxPriorityFeePerGas: `0x${this.actualChosenGwei.toString(16)}`,
        gasLimit: `0x${this.chosenGasLimit.toString(16)}`,
        to: this.walletAddress,
        value: `0x0`,
        data: '0x',
      }
      await this.signAndSendEIP1559Transaction(rawTx);
      this.isLoading = false;
    },
    async getCurrentNonce() {
      this.isLoading = true;
      if (!this.walletAddress) {
        this.$notify({
          type: "danger",
          timeout: 3000,
          message: "wallet not attached"
        });
        return;
      }
      this.nonce = await this.web3.eth.getTransactionCount(this.walletAddress);
      this.isLoading = false;
      return this.nonce;
    },
    async attachWallet() {
      if (this.privateKey) {
        try {
          this.printTextToConsole(`Key attached ${this.walletAddress ? '' : 'you forgot your wallet address'}`)
          this.wallet = new ethers.Wallet(this.privateKey.toString('hex'))
          this.getCurrentNonce();
          this.flashbotsProvider = await FlashbotsBundleProvider.create(this.httpsProvider, this.privateKey)
        } catch (e) {
          this.printTextToConsole(e.toString());
        }
      }
    },
    attachNode() {
      let cNode = localStorage.getItem("customNode");
      let isWss = (cNode || this.defaultNode).includes("ws");
      if (cNode) {
        this.customNode = cNode;
        this.web3 = new Web3(cNode);
        this.httpsProvider = isWss ? new ethers.providers.WebSocketProvider(cNode) : new ethers.providers.JsonRpcProvider(cNode);
        this.$notify(this._address + " using custom node: " + cNode)
      } else {
        this.web3 = new Web3(this.defaultNode);
        this.httpsProvider = isWss ? new ethers.providers.WebSocketProvider(this.defaultNode) : new ethers.providers.JsonRpcProvider(this.defaultNode);
        this.$notify(this._address + " using default node " + this.defaultNode)
      }
    },
  },
  mounted() {
    this.i18n = this.$i18n;
    this.attachNode();
    this.getCurrentGwei();
    if (this.privateKey) {
      this.attachWallet();
    } else {
      this.walletAddress = this._address;
      this.privateKey = this._private;
      this.attachWallet();
    }
  },
  beforeDestroy() {
    if (this.$rtl.isRTL) {
      this.i18n.locale = 'en';
      this.$rtl.disableRTL();
    }
  }
};
</script>
<style></style>
