<template>
  <div style="width: 380px">
    <a-collapse v-model="activeKey">
      <a-collapse-panel key="1" header="属性信息">
        <a-table
          v-if="data && data.length"
          :defaultExpandAllRows="true"
          :columns="columns"
          :data-source="data"
          :customRow="Rowclick"
          :pagination="false"
          :expandIconAsCell="false"
          :expandIconColumnIndex="-1"
          bordered
          size="small"
        >
          <template slot="name" slot-scope="text">
            <span style="font-weight: 600">{{ text }}</span>
          </template>
          <template
            v-for="col in ['param']"
            :slot="col"
            slot-scope="text, record"
          >
            <div v-if="record.optional.length > 0" :key="col">
              <a-select
                v-if="record.editable"
                :autoClearSearchValue="false"
                show-search
                :filter-option="true"
                v-model="record.param"
                style="width: 210px"
                :showArrow="false"
                @change="selectChange(record)"
              >
                <a-select-option
                  v-for="item in record.optional"
                  :key="item"
                  :value="item"
                  >{{ item }}</a-select-option
                >
              </a-select>
              <template v-else>
                <span :title="text">{{ text }}</span>
              </template>
            </div>
            <div v-else :key="col">
              <a-input
                v-if="record.editable"
                style="margin: -5px 0"
                :value="text"
                @change="(e) => handleChange(e.target.value, record.key, col)"
                @blur="saveData"
              />
              <template v-else>
                <span :title="text">{{ text }}</span>
              </template>
            </div>
          </template>
          <p
            v-if="record.description != ''"
            slot="expandedRowRender"
            slot-scope="record"
            style="margin: 0;font-size:13px; color: #0b6aa2"
          >
            描述：{{ record.description }}
          </p>
        </a-table>
      </a-collapse-panel>
      <a-collapse-panel key="2" header="输入资源信息" v-if="inputResourceData && inputResourceData.length">
        <a-table
          v-if="inputResourceData && inputResourceData.length"
          :columns="resourceColumns"
          :data-source="inputResourceData"
          :pagination="false"
          :customRow="InputRowclick"
          bordered
          size="small"
        >
          <template slot="name" slot-scope="text">
            <span style="font-weight: 600">{{ text }}</span>
          </template>
          <template
            v-for="col in ['resource']"
            :slot="col"
            slot-scope="text, record"
          >
            <div :key="col">
              <a-select
                v-if="record.editable"
                :autoClearSearchValue="false"
                show-search
                :filter-option="true"
                v-model="record.resource"
                style="width: 210px"
                :showArrow="false"
                @change="selectChange(record)"
              >
                <a-select-option
                  v-for="item in getResourceOptions(record.type)"
                  :key="item.name"
                  :value="item.name"
                  >{{ item.annoName }}</a-select-option
                >
              </a-select>
              <template v-else>
                <span :title="getResourceName(record.type, record.resource)">{{
                  getResourceName(record.type, record.resource)
                }}</span>
              </template>
            </div>
          </template>
        </a-table>
      </a-collapse-panel>
      <a-collapse-panel key="3" header="输出资源信息" v-if="outputResourceData && outputResourceData.length">
        <a-table
          v-if="outputResourceData && outputResourceData.length"
          :columns="resourceColumns"
          :data-source="outputResourceData"
          :pagination="false"
          :customRow="OutputRowclick"
          bordered
          size="small"
        >
          <template slot="name" slot-scope="text">
            <span style="font-weight: 600">{{ text }}</span>
          </template>
          <template slot="resource" slot-scope="text, record">
            <a-select
              v-model="record.resource"
              style="width: 220px"
              :showArrow="false"
              @change="selectChange(record)"
            >
              <a-select-option
                v-for="item in getResourceOptions(record.type)"
                :key="item.name"
                :value="item.name"
                >{{ item.annoName }}</a-select-option
              >
            </a-select>
          </template>
        </a-table>
      </a-collapse-panel>
    </a-collapse>
  </div>
</template>
<script>
import axios from "axios";

const baseUrl = process.env.API_BASE_URL ? process.env.API_BASE_URL : config.baseUrl;
const pluginPath = process.env.API_PLUGIN_PATH ? process.env.API_PLUGIN_PATH : config.pluginPath;
const resourcePath = process.env.API_RESOURCE_PATH ? process.env.API_RESOURCE_PATH : config.resourcePath;

const columns = [
  {
    title: "属性名称",
    dataIndex: "annoName",
    width: "120px",
    scopedSlots: { customRender: "name" },
  },
  {
    title: "参数",
    dataIndex: "param",
    width: "180px",
    scopedSlots: { customRender: "param" },
    ellipsis: true,
  },
];

const resourceColumns = [
  {
    title: "资源名称",
    dataIndex: "description",
    width: "120px",
    scopedSlots: { customRender: "name" },
  },
  {
    title: "资源",
    dataIndex: "resource",
    width: "180px",
    scopedSlots: { customRender: "resource" },
    ellipsis: true,
  },
];

const data = [];
const inputResourceData = [];
const outputResourceData = [];

export default {
  data() {
    this.cacheData = data.map((item) => ({ ...item }));
    this.inputcacheData = inputResourceData.map((item) => ({ ...item }));
    this.outputcacheData = outputResourceData.map((item) => ({ ...item }));
    return {
      data,
      columns,
      inputResourceData,
      outputResourceData,
      resourceColumns,
      activeKey: ["1", "2", "3"],
      top: 0,
      resourceList: [],
      baseUrl,
      pluginPath,
      resourcePath,
    };
  },
  mounted() {
    let that = this;

    that.getResources();
    
    window.addEventListener("message", (event) => {
      var messageData = event.data;
      if (messageData.cmd == "clickNode") {
        var type = messageData.params.type;
        var property = messageData.params.property;

        let paramData = [];
        let inputData = [];
        let outputData = [];
        if (property != "") {
          paramData = property.params;
          inputData = property.resources.inputs;
          outputData = property.resources.outputs;
        }

        that.data = [];
        axios
          .get(that.baseUrl + that.pluginPath + type)
          .then(function (res) {
            for (let i = 0; i < res.data.params.length; i++) {
              let nodePropertyParam = paramData.find((a) => a.name == res.data.params[i].name);
              that.data.push({
                key: i.toString(),
                name: res.data.params[i].name,
                annoName: res.data.params[i].annoName,
                description: res.data.params[i].description,
                param: nodePropertyParam ? nodePropertyParam.value : (res.data.params[i].optional.length > 0 ? that.getDefaultParam(res.data.params[i].optional) : res.data.params[i].default) ,
                optional: res.data.params[i].optional,
              });
            }

            that.inputResourceData = [];
            for (let i = 0; i < res.data.resources.inputs.length; i++) {
              let nodePropertyInput = inputData.find((a) => a.name == res.data.resources.inputs[i].name);
              that.inputResourceData.push({
                key: i.toString(),
                name: res.data.resources.inputs[i].name,
                description: res.data.resources.inputs[i].description,
                resource: nodePropertyInput ? nodePropertyInput.resource : that.getFirstOption(res.data.resources.inputs[i].type),
                optional: res.data.resources.inputs[i].optional,
                type: res.data.resources.inputs[i].type,
              });
            }

            that.outputResourceData = [];
            for (let i = 0; i < res.data.resources.outputs.length; i++) {
              let nodePropertyOutput = outputData.find((a) => a.name == res.data.resources.outputs[i].name);
              that.outputResourceData.push({
                key: i.toString(),
                name: res.data.resources.outputs[i].name,
                description: res.data.resources.outputs[i].description,
                resource: nodePropertyOutput ? nodePropertyOutput.resource : that.getFirstOption(res.data.resources.inputs[i].type),
                optional: res.data.resources.outputs[i].optional,
                type: res.data.resources.outputs[i].type,
              });
            }

            that.cacheData = that.data.map((item) => ({ ...item }));
            that.inputcacheData = that.inputResourceData.map((item) => ({...item,}));
            that.outputcacheData = that.outputResourceData.map((item) => ({...item,}));
          })
          .catch(function (error) {
            console.log(error);
          });
      }
    });

      /*
       axios
          .get("http://172.18.67.133:5000/api/app/plugin/bugdigger")
          .then(function (res) {
            that.data = [];
            for (let i = 0; i < res.data.params.length; i++) {
              that.data.push({
                key: i.toString(),
                name: res.data.params[i].name,
                annoName: res.data.params[i].annoName,
                description: res.data.params[i].description,
                param: res.data.params[i].optional.length > 0 ? that.getDefaultParam(res.data.params[i].optional) : res.data.params[i].default ,
                optional: res.data.params[i].optional,
              });
            }

            that.inputResourceData = [];
            for (let i = 0; i < res.data.resources.inputs.length; i++) {
              that.inputResourceData.push({
                key: i.toString(),
                name: res.data.resources.inputs[i].name,
                description: res.data.resources.inputs[i].description,
                resource: that.getFirstOption(res.data.resources.inputs[i].type),
                optional: res.data.resources.inputs[i].optional,
                type: res.data.resources.inputs[i].type,
              });
            }

            that.outputResourceData = [];
            for (let i = 0; i < res.data.resources.outputs.length; i++) {
              that.outputResourceData.push({
                key: i.toString(),
                name: res.data.resources.outputs[i].name,
                description: res.data.resources.outputs[i].description,
                resource: that.getFirstOption(res.data.resources.inputs[i].type),
                optional: res.data.resources.outputs[i].optional,
                type: res.data.resources.outputs[i].type,
              });
            }

            that.cacheData = that.data.map((item) => ({ ...item }));
            that.inputcacheData = that.inputResourceData.map((item) => ({...item,}));
            that.outputcacheData = that.outputResourceData.map((item) => ({...item,}));
          })
          .catch(function (error) {
            console.log(error);
          });
          */
  },
  methods: {
    getDefaultParam(optional){
      if(optional.length > 0) {
        return optional[0]
      } else {
        return ""
      }
    },
    getFirstOption(type){
      let targetResource = this.resourceList.filter((e) => e.name == type);
      let resources = targetResource[0].resources;
      if(resources.length > 0){
        return resources[0].name
      } else {
        return "";
      }
    },
    selectChange(record) {
      this.saveData();

      const newData = [...this.data];
      const newCacheData = [...this.cacheData];
      const target = newData.filter((item) => record.name === item.name)[0];
      const targetCache = newCacheData.filter((item) => record.name === item.name)[0];

      if (target && targetCache) {
        delete target.editable;
        this.data = newData;
        Object.assign(targetCache, target);
        this.cacheData = newCacheData;
      }

      const newInputData = [...this.inputResourceData];
      const newInputCacheData = [...this.inputcacheData];
      const targetInput = newInputData.filter((item) => record.name === item.name)[0];
      const targetInputCache = newInputCacheData.filter((item) => record.name === item.name)[0];

      if (targetInput && targetInputCache) {
        delete targetInput.editable;
        this.inputResourceData = newInputData;
        Object.assign(targetInputCache, targetInput);
        this.inputcacheData = newInputCacheData;
      }

      const newOuputData = [...this.outputResourceData];
      const newOutputCacheData = [...this.outputcacheData];
      const targetOutput = newInputData.filter((item) => record.name === item.name)[0];
      const targetOutputCache = newInputCacheData.filter((item) => record.name === item.name)[0];

      if (targetOutput && targetOutputCache) {
        delete targetOutput.editable;
        this.outputResourceData = newOuputData;
        Object.assign(targetOutputCache, targetOutput);
        this.outputcacheData = newOutputCacheData;
      }
    },
    getResourceOptions(type) {
      let targetResource = this.resourceList.filter((e) => e.name == type);
      let resources = targetResource[0].resources;
      return resources;
    },
    getResourceName(type, name) {
      let targetResource = this.resourceList.filter((e) => e.name == type);
      let resources = targetResource[0].resources;
      let resource = resources.filter((e) => e.name == name);
      let annoName = ""
      if(resource.length > 0){
        annoName = resource[0].annoName;
      }
      return annoName;
    },
    getResources() {
      let that = this;
      axios
        .get(that.baseUrl + this.resourcePath)
        .then(function (res) {
          that.resourceList = res.data;
        })
        .catch(function (error) {
          console.log(error);
        });
    },
    handleChange(value, key, column) {
      const newData = [...this.data];
      const target = newData.filter((item) => key === item.key)[0];
      if (target) {
        target[column] = value;
        this.data = newData;
      }
    },
    Rowclick(record, index) {
      return {
        on: {
          click: () => {}, //表格行 点击事件
          dblclick: () => {}, //表格行 双击事件
          mouseenter: (event) => {
            const newData = [...this.data];
            const target = newData.filter((item) => record.key === item.key)[0];
            if (target) {
              target.editable = true;
              this.data = newData;
            }
          },
          mouseleave: (event) => {
            const newData = [...this.data];
            const newCacheData = [...this.cacheData];
            const target = newData.filter((item) => record.key === item.key)[0];
            const targetCache = newCacheData.filter(
              (item) => record.key === item.key
            )[0];
            if (target && targetCache && target.optional.length == 0) {
              delete target.editable;
              this.data = newData;
              Object.assign(targetCache, target);
              this.cacheData = newCacheData;
            }
          },
        },
      };
    },
    InputRowclick(record, index) {
      return {
        on: {
          click: () => {}, //表格行 点击事件
          dblclick: () => {}, //表格行 双击事件
          mouseenter: (event) => {
            const newData = [...this.inputResourceData];
            const target = newData.filter((item) => record.key === item.key)[0];
            if (target) {
              target.editable = true;
              this.inputResourceData = newData;
            }
          },
          mouseleave: (event) => {},
        },
      };
    },
    OutputRowclick(record, index){
      return {
        on: {
          click: () => {}, //表格行 点击事件
          dblclick: () => {}, //表格行 双击事件
          mouseenter: (event) => {
            const newData = [...this.outputResourceData];
            const target = newData.filter((item) => record.key === item.key)[0];
            if (target) {
              target.editable = true;
              this.outputResourceData = newData;
            }
          },
          mouseleave: (event) => {},
        },
      };
    },
    saveData() {
      let data = {};
      let paramsData = [];
      let resources = {};
      let inputsData = [];
      let outputsData = [];

      this.data.forEach((e) => {
        paramsData.push({ name: e.name, value: e.param });
      });

      this.inputResourceData.forEach((e) => {
        inputsData.push({ name: e.name, resource: e.resource });
      });

      this.outputResourceData.forEach((e) => {
        outputsData.push({ name: e.name, resource: e.resource });
      });

      resources["inputs"] = inputsData;
      resources["outputs"] = outputsData;

      data["resources"] = resources;
      data["params"] = paramsData;

      window.parent.postMessage(
        {
          cmd: "property",
          params: {
            data: data,
          },
        },
        "*"
      );
    },
  },
};
</script>
<style scoped>
.editable-row-operations a {
  margin-right: 8px;
}

.ant-table-body {
  overflow-x: auto !important;
}

.ant-table-thead {
  background: cadetblue;
}
</style>
