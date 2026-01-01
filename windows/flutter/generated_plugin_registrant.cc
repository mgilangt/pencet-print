//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <pdfx/pdfx_plugin.h>
#include <print_bluetooth_thermal/print_bluetooth_thermal_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  PdfxPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PdfxPlugin"));
  PrintBluetoothThermalPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PrintBluetoothThermalPluginCApi"));
}
