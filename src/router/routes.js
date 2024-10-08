import DashboardLayout from "@/layout/dashboard/DashboardLayout.vue";
// GeneralViews
import NotFound from "@/pages/NotFoundPage.vue";

// Admin pages
const Dashboard = () => import(/* webpackChunkName: "dashboard" */"@/pages/Dashboard.vue");
const Profile = () => import(/* webpackChunkName: "common" */ "@/pages/Profile.vue");
const Belongings = () => import(/* webpackChunkName: "common" */ "@/pages/Belongings.vue");
const EthUniswapV3 = () => import(/* webpackChunkName: "common" */ "@/pages/EthUniswapV3.vue");
const Execute404 = () => import(/* webpackChunkName: "common" */ "@/pages/Execute404.vue");
const Interactions = () => import(/* webpackChunkName: "common" */ "@/pages/Interactions.vue");
const Dumbot = () => import(/* webpackChunkName: "common" */ "@/pages/Dumbot.vue");
const EtherVista = () => import(/* webpackChunkName: "common" */ "@/pages/EtherVista.vue");
const Spammer = () => import(/* webpackChunkName: "common" */ "@/pages/Spammer.vue");
const BlocksView = () => import(/* webpackChunkName: "common" */ "@/pages/BlocksView.vue");
const Notifications = () => import(/* webpackChunkName: "common" */"@/pages/Notifications.vue");
const Icons = () => import(/* webpackChunkName: "common" */ "@/pages/Icons.vue");
const Maps = () => import(/* webpackChunkName: "common" */ "@/pages/Maps.vue");
const Typography = () => import(/* webpackChunkName: "common" */ "@/pages/Typography.vue");
const TableList = () => import(/* webpackChunkName: "common" */ "@/pages/TableList.vue");

const routes = [
  {
    path: "/",
    component: DashboardLayout,
    redirect: "/dashboard",
    children: [
      {
        path: "dashboard",
        name: "dashboard",
        component: Dashboard
      },
      {
        path: "belongings",
        name: "Belongings",
        component: Belongings
      },
      {
        path: "uniswapv3",
        name: "EthUniswapV3",
        component: EthUniswapV3
      },
      {
        path: "execute404",
        name: "execute404",
        component: Execute404
      },
      {
        path: "interactions",
        name: "Interactions",
        component: Interactions
      },
      {
        path: "DumBot",
        name: "Dumbot",
        component: Dumbot
      },
      {
        path: "Spammer",
        name: "Spammer",
        component: Spammer
      },  
       {
        path: "blocks",
        name: "blocks",
        component: BlocksView
      },
      {
        path: "EtherVista",
        name: "EtherVista",
        component: EtherVista
      },
      {
        path: "profile",
        name: "profile",
        component: Profile
      },
      {
        path: "notifications",
        name: "notifications",
        component: Notifications
      },
      {
        path: "icons",
        name: "icons",
        component: Icons
      },
      {
        path: "maps",
        name: "maps",
        component: Maps
      },
      {
        path: "typography",
        name: "typography",
        component: Typography
      },
      {
        path: "table-list",
        name: "table-list",
        component: TableList
      }
    ]
  },
  { path: "*", component: NotFound },
];

/**
 * Asynchronously load view (Webpack Lazy loading compatible)
 * The specified component must be inside the Views folder
 * @param  {string} name  the filename (basename) of the view to load.
function view(name) {
   var res= require('../components/Dashboard/Views/' + name + '.vue');
   return res;
};**/

export default routes;
