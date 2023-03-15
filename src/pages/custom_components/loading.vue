<template>
    <div class="lds-ripple">
        <div></div>
        <div></div>
    </div>
</template>
<script>
export default {
    components: {},
    data() {
        return {}
    },
    computed: {},
    methods: {},
};
</script>
<style>
.lds-ripple {
    display: inline-block;
    position: absolute;
    width: 10px;
    height: 10px;
}

.lds-ripple div {
    position: absolute;
    border: 1.5px solid #fff;
    opacity: 1;
    border-radius: 50%;
    animation: lds-ripple 1s cubic-bezier(0, 0.2, 0.8, 1) infinite;
}

.lds-ripple div:nth-child(2) {
    animation-delay: -0.5s;
}

@keyframes lds-ripple {
    0% {
        top: 16px;
        left: 16px;
        width: 0;
        height: 0;
        opacity: 0;
    }

    4.9% {
        top: 16px;
        left: 16px;
        width: 0;
        height: 0;
        opacity: 0;
    }

    5% {
        top: 16px;
        left: 16px;
        width: 0;
        height: 0;
        opacity: 1;
    }

    100% {
        top: 0px;
        left: 0px;
        width: 32px;
        height: 32px;
        opacity: 0;
    }
}</style>
  