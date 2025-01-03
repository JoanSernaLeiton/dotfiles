keymaps = {
  insert = "<C-g>s",         -- En modo insert, rodea el texto seleccionado en el lugar.
  insert_line = "<C-g>S",    -- En modo insert, rodea toda la línea en el lugar.

  normal = "gsa",            -- En modo normal, agrega un rodeado alrededor de un movimiento (por ejemplo, una palabra o un bloque específico).
  normal_cur = "gss",        -- En modo normal, agrega un rodeado alrededor de la línea actual.

  normal_line = "gsA",       -- En modo normal, agrega un rodeado alrededor de un movimiento específico en nuevas líneas.
  normal_cur_line = "gSS",   -- En modo normal, rodea la línea actual en nuevas líneas.

  visual = "S",              -- En modo visual, rodea la selección directamente.
  visual_line = "gS",        -- En modo visual, rodea toda la línea seleccionada directamente.

  delete = "ds",             -- Elimina un rodeado específico.
  change = "cs",             -- Cambia el rodeado por otro en el lugar.
  change_line = "cS",        -- Cambia el rodeado de toda la línea.
}
