<template>
  <div>
    <input type="file" @change="tryImportWallets" class="form" accept="application/JSON" style="width: 120px; font-size: 10px;" />
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
      wallets: [],
    }
  },
  computed: {

  },
  methods: {
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
