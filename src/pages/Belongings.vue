<template>
  <div>
    <input type="file" @change="tryImportWallets" class="form" accept="application/JSON" style="width: 120px; font-size: 10px;" />
    <div class="row mt-5" v-if="wallets.length == 0">
      <div class="col-3">
        <p class="text-danger">if you dont have a file yet you can set up your wallets file here after submitting all the info for a wallet press + it will add it when your done download the file and you'll be using this file next time </p>
      </div>
      <div class="col-4">
        <base-input type="text" placeholder="name" v-model="name"></base-input>
        <base-input type="text" placeholder="address" v-model="add"></base-input>
        <base-input type="password" placeholder="private" v-model="priv"></base-input>
        <base-button @click="addWallet">+</base-button>
        <a href="" id="downloadAnchorElem">download</a>

        <p v-for="p in preWallets" :key="p.address"> {{ p.address }}</p>
      </div>
    </div>
    <div class="row">
      <div class="col-4" v-for="w in wallets" :key="w.address">
        <h4 class="mt-5 mb-0">{{ w.name }}</h4>
        <br>
        <EasySwapVue :_address="w.address" :_private="w.private"/>
      </div>
    </div>
  </div>
</template>
<script>
import loading from "@/pages/custom_components/loading.vue";
import EasySwapVue from './EasySwap.vue';
export default {
  components: { loading, EasySwapVue },
  data() {
    return {
      name:"",
      add: "",
      priv:"",
      wallets: [],
      preWallets: []
    }
  },
  computed: {

  },
  methods: {
    addWallet(){
      this.preWallets.push({name: this.name, address: this.add, private: this.priv});
      var dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(this.preWallets));
      var dlAnchorElem = document.getElementById('downloadAnchorElem');
      dlAnchorElem.setAttribute("href",     dataStr     );
      dlAnchorElem.setAttribute("download", "myShit.json");
    },
    async tryImportWallets(e) {
      let file_to_read = e.target.files[0];
      var fileread = new FileReader();
      fileread.onload = (e) => {
        var content = e.target.result;
        var intern = JSON.parse(content); // Array of Objects.
        console.log(intern); // You can index every object
        this.wallets = intern;
        // this.showWallet(this.wallets[0].address)
      };
      fileread.readAsText(file_to_read);

      console.log(e);
    },
    async getWalletBalance(address){
      this.isLoading = true;
      this.walletBalance = await this.httpsProvider.getBalance(address);
      this.walletBalance /= Math.pow(10, 18);
      this.walletBalance = this.walletBalance.toFixed(2)
      this.isLoading = false;
    },
  },
  mounted() {
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
