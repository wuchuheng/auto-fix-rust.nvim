local M = {}

function M.setup()
	vim.api.nvim_create_autocmd("BufWritePre", {
		pattern = "*.rs",
		callback = function()
			-- 1 Save current buffer file and dont shoe the message.
			-- Slient write the current buffer file.
			vim.api.nvim_command("silent w")
			-- Check the cmd `cargo` was installed.
			local is_cargo_installed = vim.fn.executable("cargo") == 1
			if not is_cargo_installed then
				return
			end
			-- 2 Get the currrent project root path and print.
			local project_root = vim.fn.system("cargo metadata --no-deps --format-version 1 | jq -r .workspace_root")
			-- 3 Execute the cmd: `cargo fix --allow-dirty` in the project root path. and get the error output.
			local output = vim.fn.system("cd " .. project_root .. "; cargo fix --allow-dirty")
			-- Error output example:
			--     error: expected `;`, found `println`
			--  --> src/main.rs:4:34
			--   |
			-- 4 |     println!("Guess the number!")
			--   |                                  ^ help: add `;` here
			-- ...
			-- 7 |     println!("Please input your guess.");
			--   |     ------- unexpected token

			-- 4 If the error message was expected `;`, found `help: add `;` here` the line number and column number will be extracted.
			-- -- Aan then add the `;` to the end of the line.
			-- 4.1 loop every line in the output to collect the error file path, line number and column number,
			-- Store the new output as array.
			local newOutputList = {}
			local isExpectedError = false
			local index = 1
			local tmpOutput = ""
			local errorMessageSymbole = "error: expected `;`"

			for line in output:gmatch("[^\r\n]+") do
				if isExpectedError then
					-- 4.2 If the line is the error message;
					if line:find("error: ") then
						-- 4.2.1 If the tmpOutput is not empty, add the tmpOutput to the newOutputList.
						if tmpOutput ~= "" then
							newOutputList[index] = tmpOutput
							tmpOutput = ""
							index = index + 1
						end
						-- 4.2.2 If the error message was not expected `error: expected `;`, found `println``, and then set the isExpectedError to false.
						if not line:find(errorMessageSymbole) then
							isExpectedError = false
						end
						-- continue to the next line.
						goto continue
					end
					tmpOutput = tmpOutput .. line .. "\n"
				else
					-- 4.3 If the line is Error message, and the error message was expected: error: expected `;`
					if line:find(errorMessageSymbole) then
						isExpectedError = true
					end
				end
				::continue::
			end
			-- local lenght of the newOutputList
			-- 4.4 If the tmpOutput is not empty, add the tmpOutput to the newOutputList.
			if tmpOutput ~= "" then
				newOutputList[index] = tmpOutput
			end

			-- 5 Add the `;` to the end of the line.
			-- 5.1 Print the new output. loop every line in the new output and print.
			for _, line in ipairs(newOutputList) do
				-- 5.3 To update the `;` to current buffer file.
				-- 5.4 Splite the line with `\n`and get the first line.
				local first_line = string.match(line, "^(.-)\n")
				-- 5.5 Extract the line number, the file path  and column number from the string like: `src/main.rs:4:34`
				local file_path, line_number, column_number = string.match(first_line, "([^-|^>]+):(%d+):(%d+)")
				-- Remove the space chars in the file_path.
				-- Get the current buffer file name.
				local file_name = vim.fn.expand("%")
				local fix_file_path = string.gsub(file_path, "%s+", "")
				-- if the file was not the same as the current buffer file, continue to the next line.
				if fix_file_path ~= file_name then
					goto line_continue
				end

				line_number = line_number - 1
				-- 6 add the `;` to the end of the line.
				local bufnr = vim.api.nvim_get_current_buf()
				-- Get the line content
				local lines = vim.api.nvim_buf_get_lines(bufnr, line_number, line_number + 1, false)
				local line_content = lines[1]

				-- Modify the line content by inserting a semicolon at the specified column
				local modified_line_content = line_content:sub(1, column_number - 1)
					.. ";"
					.. line_content:sub(column_number)

				-- Set the modified line back into the buffer
				vim.api.nvim_buf_set_lines(bufnr, line_number, line_number + 1, false, { modified_line_content })
				::line_continue::
			end
		end,
	})
end

return M
