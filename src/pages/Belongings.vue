<template>
  <div>
    <div class="row">
      <div class="col" v-if="chartToken">
        <base-button @click="refreshChart"><i class="tim-icons icon-refresh-01"></i></base-button>
        <base-button @click="chartToken = null"><i class="tim-icons icon-simple-remove"></i></base-button>
        <div class="text-center" style="overflow-y: scroll; height: 810px;" v-if="chartRefresh">
          <iframe :src="`https://dexscreener.com/ethereum/${chartToken}`" frameborder="0" width="100%"
            height="800px"></iframe>
        </div>

      </div>
    </div>
    <input type="file" @change="tryImportWallets" class="form" accept="application/JSON"
      style="width: 120px; font-size: 10px;" v-if="wallets.length == 0" />
    <div class="row mt-5" v-if="wallets.length == 0">
      <div class="col-3">
        <p class="text-danger">if you dont have a file yet you can set up your wallets file here after submitting all the
          info for a wallet press + it will add it when your done download the file and you'll be using this file next
          time </p>
      </div>
      <div class="col-4">
        <base-input type="password" class="mb-5" placeholder="encryption password" v-model="enc"></base-input>

        <base-input type="text" placeholder="name" v-model="name"></base-input>
        <base-input type="text" placeholder="address" v-model="add"></base-input>
        <base-input type="password" placeholder="private" v-model="priv"></base-input>
        <base-button @click="addWallet">+</base-button>
        <a href="" id="downloadAnchorElem">download</a>

        <p v-for="p in preWallets" :key="p.address"> {{ p.address }}</p>
      </div>
    </div>
    <br>
    <div v-if="wallets.length > 0" class="mb-3">
      <base-button @click="guiRefresh = !guiRefresh">double click to reset all wallets</base-button>
      <base-button @click="refreshGas">{{ currentGwei }}</base-button>
      <div class="row">
        <div class="col">
          <base-input type="text" placeholder="token address" v-model="token_address"
            style="width: 30%; float: right;" @click="pasteContract"></base-input>
        </div>
        <div class="col">
          <base-button @click="checkWalletsContainingTokenAddress">
          <i class="tim-icons icon-zoom-split"></i>
        </base-button>
          <base-button @click="refreshWallets">
          <i class="tim-icons icon-refresh-02"></i>
        </base-button>
        <base-button title="click to manage wallets file" @click="editWallets = !editWallets">
          <i class="tim-icons icon-settings-gear-63"></i>
        </base-button>
        <base-button title="click to add a wallet in your new file" @click="addWalletToFile">
          +
        </base-button>
        </div>
      </div>
    </div>

    <div class="row" v-if="editWallets">
      <div v-for="(w, walletIndex) in wallets" class="col" :key="`_${w.address}`">
        <base-input type="text" placeholder="Address" :value="w.address" disabled></base-input>
        <base-button  title="click to remove this wallet" @click="removeWallet(walletIndex)">
          <i class="tim-icons icon-simple-remove"></i>
        </base-button>
      </div>
    </div>

    <div class="row" v-if="guiRefresh">
      <div class="col-4" v-for="w in wallets" :key="w.address">
        <h5 class="mt-5 mb-0" v-if="token_owners.includes(w.address)"><a target="_blank" :href="`https://etherscan.io/address/${w.address}`">{{ w.name }}</a>
        </h5>
        <br>
        <EasySwapVue :_address="w.address" :_private="w.private" v-if="token_owners.includes(w.address)" :currentToken="token_owners.includes(w.address) ? token_address : null"/>
      </div>
    </div>
  </div>
</template>
<script>
import loading from "@/pages/custom_components/loading.vue";
import EasySwapVue from './EasySwap.vue';
import Web3 from "web3";
import GroupBelongings from "./GroupBelongings.vue";
export default {
  components: { loading, EasySwapVue, GroupBelongings },
  data() {
    return {
      trackedProject: 0,
      chartToken: "",
      guiRefresh: true,
      enc: "",
      name: "",
      add: "",
      priv: "",
      wallets: [],
      preWallets: [],
      currentGwei: 0,
      web3: null,
      chartRefresh: true,
      token_address: "",
      token_owners: [],
      editWallets: false,
    }
  },
  computed: {

  },
  methods: {
    addWalletToFile(){
      let prevWallets = this.wallets;
      this.wallets = [];
      for(let i = 0 ; i < prevWallets.length; i++){
        this.name = prevWallets[i].name;
        this.add = prevWallets[i].address;
        this.priv = prevWallets[i].private;
        this.addWallet();
      }
    },
    removeWallet(wIndex){
      this.wallets.splice(wIndex, 1)
    },
    openChart(address) {
      this.chartToken = address;
    },
    closeChart() {
      this.chartToken = null
    },

    async pasteContract() {
      this.token_address = await navigator.clipboard.readText();
      await this.checkWalletsContainingTokenAddress();
    },

    refreshChart() {
      this.chartRefresh = !this.chartRefresh;
      setTimeout(() => {
        this.chartRefresh = !this.chartRefresh;
      }, 100);

    },
    refreshWallets(){
      this.token_owners = this.wallets.map(x=> {return x.address})
      this.token_address = ""
    },
    async checkWalletsContainingTokenAddress() {
      let minABI = [
        // balanceOf
        {
          "constant": true,
          "inputs": [{ "name": "_owner", "type": "address" }],
          "name": "balanceOf",
          "outputs": [{ "name": "balance", "type": "uint256" }],
          "type": "function"
        },
        // decimals
        {
          "constant": true,
          "inputs": [],
          "name": "decimals",
          "outputs": [{ "name": "", "type": "uint8" }],
          "type": "function"
        }
      ];
      let contract_address = this.token_address;
      let adresses_to_check = this.wallets.map(x => { return x.address });
      let contract = new this.web3.eth.Contract(minABI, contract_address);
      let owners = [];
      for (let i = 0; i < adresses_to_check.length; i++) {
        let addy = adresses_to_check[i];
        let balance = await contract.methods.balanceOf(addy).call();
        if (balance > 0) {
          owners.push(addy);
        }
      }
      this.token_owners = owners;
    },
    async refreshGas() {
      let cNode = "https://rpc.mevblocker.io/";
      this.web3 = new Web3(cNode);
      this.currentGwei = 0;
      let gas = await this.web3.eth.getGasPrice();
      this.currentGwei = Math.ceil(gas / Math.pow(10, 9));
    },
    addWallet() {
      this.preWallets.push({ name: this.name, address: this.add, private: this.priv });
      let encrypted = this.CryptoJS.AES.encrypt(JSON.stringify(this.preWallets), "_1_" + this.enc).toString();
      var dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(encrypted);
      var dlAnchorElem = document.getElementById('downloadAnchorElem');
      if(dlAnchorElem){
        dlAnchorElem.setAttribute("href", dataStr);
        dlAnchorElem.setAttribute("download", "myShit.json");  
      }else{
        setTimeout(() => {
          dlAnchorElem = document.getElementById('downloadAnchorElem');
          dlAnchorElem.setAttribute("href", dataStr);
          dlAnchorElem.setAttribute("download", "myShit.json");  
        }, 1000);
      }
      
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
          this.wallets = intern;
          this.refreshWallets();
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
    async getWalletBalance(address) {
      this.isLoading = true;
      this.walletBalance = await this.httpsProvider.getBalance(address);
      this.walletBalance /= Math.pow(10, 18);
      this.walletBalance = this.walletBalance.toFixed(2)
      this.isLoading = false;
    },
  },
  mounted() {
    this.refreshGas();
    // this.attachNode();
    // this.getCurrentGwei();
    // if (this.privateKey) {
    //   this.attachWallet();
    // } else {
    //   this.walletAddress = this._address;
    //   this.privateKey = this._private;
    //   this.attachWallet();
    // }
  },
  beforeDestroy() {

  }
};
</script>
<style></style>
