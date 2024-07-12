using namespace System.Management.Automation
using namespace System.Management.Automation.Language

$_ealiases = [ordered]@{}

function _lookup_ealias() {
  param([string]$Name)

  $metadata = _lookup_ealias_metadata($Name)
  if ($null -eq $metadata) {
    return $null
  }
  return $metadata.ExpandsTo
}

function _lookup_ealias_metadata() {
  param([string]$Name)
  return $_ealiases[$Name]
}

function abbr() {
  # for compat w/ fish abbr (that zsh now understands)
  #   BONUS: abbr uses two args like ealias (below) in powershell, so finally I can have one style across ps1,zsh,fish for vanilla expansions!
  # PRN if it saves time make abbr into expansion only, leave ealias for composable+expansions like fish (and maybe port to zsh too)... if it doesn't matter for startup time then don't bother
  ealias $args[0] $args[1]
}

function ealias() {
  # usage:
  #   ealias foo bar
  #   ealias gcmsg 'git commit -m "' -NoSpaceAfter
  #   ealias pyml '| yq' -Anywhere => 'kubectl get pods -o yaml pyml[EXPANDS]'
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$ExpandsTo,
    [Parameter(Mandatory = $false)][switch]$NoSpaceAfter = $false,
    [Parameter(Mandatory = $false)][switch]$Anywhere = $false
  )

  # *** use set-alias to see the $_cmd in MENU COMPLETION TOOL TIPS
  #   also allows `gcm foo` to lookup expanding aliases
  Set-Alias $Name "$ExpandsTo" -Scope Global

  # metadata/lookup outside of set-alias objects
  $_ealiases[$Name] = @{
    ExpandsTo    = $ExpandsTo
    NoSpaceAfter = $NoSpaceAfter
    Anywhere     = $Anywhere
  }

}

function ExpandAliasBeforeCursor {
  param($key, $arg)
  # FYI this is split out for users to bind to other key(s) besides space, or to recompose with custom bindings of their own

  # Add space, then invoke replacement logic
  #   b/c override spacebar handler, there won't be a space unless I add it
  # inserts at current cursor position - important to do that now b/c the cursor is where the user intended the space, whereas after modification the cursor might be elsewhere (ie after Replace below)
  [Microsoft.PowerShell.PSConsoleReadLine]::Insert(" ")
  # help for Insert overloads
  # https://docs.microsoft.com/en-us/dotnet/api/microsoft.powershell.psconsolereadline.insert

  $ast = $null
  $tokens = $null
  $errors = $null
  $cursor = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

  # this must handle cumulative adjustments from multiple replaces but the thing is after each space I would've already replaced previous ealiases
  #   in fact if I copy/paste smth like `dcr dcr dcr` the spaces trigger on paste to expand already
  #   so, I theoretically could stop after first replacement
  $startAdjustment = 0

  foreach ($token in $tokens) {
    # IIRC it was easier to expand on all tokens every time... I could revise this to take into account cursor position and only expand the last argument (before cursor) and then also support cursor in middle of command line too... but I won't add any of that until an issue arises as this has worked perfectly fine all along... could do smth like last token right before cursor position?

    $original = $token.Extent

    $metadata = _lookup_ealias_metadata($original.Text)
    if ($null -eq $metadata -or $null -eq $metadata.ExpandsTo) {
      continue
    }

    $anywhere = $metadata.Anywhere
    $is_command_position = $token -eq $tokens[0] # PRN if this has edge cases where command isn't first token, then address that once the problem arises, for now assume this works (to check $tokens[0])
    if (-not $anywhere -and -not $is_command_position) {
      # skip if not in command position and not marked anywhere
      continue
    }

    $expands_to = $metadata.ExpandsTo

    if (-not $metadata.NoSpaceAfter) {
      # add a space unless alias defined with NoSpaceAfter
      #   i.e. `gcmsg` expands to `git commit -m "` w/o trailing space
      $expands_to = "$expands_to "

      # IIRC I had an open question about why I have to add space here again... but its working as is so leave it, IIAC this is b/c tokenizer strips them?
    }

    $original_length = $original.EndOffset - $original.StartOffset
    [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
      $original.StartOffset + $startAdjustment,
      $original_length,
      $expands_to)

    # Our copy of tokens isn't updated, so adjust by the difference in length
    $startAdjustment += $expands_to.Length - $original_length
  }

  # PRN => if any expansions then take another pass! until no more expansions b/c then I can supported nested expansions!
  # i.e.:
  #   ealias foo bar
  #   ealias bar baz
  #   foo => expands to `bar` => expands to `baz`
  #   right now I only expand to `bar` and stop which has been sufficient for now

}

### Spacebar => triggers expansion
#
# scenarios:
# - typing `drc<SPACE>` => expands
# - completion: `gs<TAB>` => menu shows, tab through items, hit space to select (triggers expand)
#   - if I hit enter to select an item, space can be used after that to expand it => PRN I could impl a handler for enter during completion but lets not complicate it
#
Set-PSReadLineKeyHandler -Key "Spacebar" `
  -BriefDescription "space expands ealiases" `
  -LongDescription "Spacebar handler to expand all ealiases in current line/buffer, primarily intended for ealias right before current cursor position" `
  -ScriptBlock ${function:ExpandAliasBeforeCursor}


### ENTER => triggers expansion
# i.e. if type `dcr<ENTER>` it expands to `docker-compose run` b/c of this
#
# enable validate handler (on enter):
Set-PSReadLineKeyHandler -Key Enter -Function ValidateAndAcceptLine
#

function ExpandAliasesCommandValidationHandler {
  param([CommandAst]$CommandAst)

  # I split out this function so end users can re-compose it with additional validation handler logic of their own

  $possibleAlias = $CommandAst.GetCommandName()
  # don't need metadata b/c NoSpaceAfter (only option) doesn't apply to this handler b/c this is after executing the command (possible alias) so line editing is done
  $expands_to = _lookup_ealias($possibleAlias)
  if ($null -eq $expands_to) {
    return
  }

  $original = $CommandAst.CommandElements[0].Extent
  [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
    $original.StartOffset,
    $original.EndOffset - $original.StartOffset,
    $expands_to
  )

}

Set-PSReadLineOption -CommandValidationHandler ${function:ExpandAliasesCommandValidationHandler}

## Examples
# CommandValidationHandler: https://github.com/PowerShell/PSReadLine/issues/1643
# https://www.powershellgallery.com/packages/PSReadline/1.2/Content/SamplePSReadlineProfile.ps1
