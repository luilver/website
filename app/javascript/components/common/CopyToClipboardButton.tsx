import React, { useCallback, useEffect, useState, useRef } from 'react'
import { copyToClipboard } from '../../utils/copyToClipboard'
import { Icon } from './Icon'

const KEY_NAMES = Object.freeze({
  SPACE: ' ',
})

const KEY_NAMES_LEGACY = Object.freeze({
  SPACE: 'Space',
})

export function CopyToClipboardButton({ textToCopy }: { textToCopy: string }) {
  const buttonRef = useRef<HTMLButtonElement | null>(null)
  const [justCopied, setJustCopied] = useState(false)

  const copyTextToClipboard = async () => {
    await copyToClipboard(textToCopy)
    setJustCopied(true)
  }

  const onKeyPress = useCallback(
    async (e: KeyboardEvent) => {
      if ((e.code === 'KeyC' || e.key === 'c') && (e.ctrlKey || e.metaKey)) {
        e.preventDefault()
        await copyTextToClipboard()
        return
      }

      if (e.key === KEY_NAMES_LEGACY.SPACE || e.key === KEY_NAMES.SPACE) {
        e.preventDefault()
        buttonRef.current?.click()
        return
      }
    },

    [textToCopy, setJustCopied]
  )

  const onClick = useCallback(
    async (e) => {
      e.preventDefault()
      await copyTextToClipboard()
    },
    [textToCopy, setJustCopied]
  )

  const onFocus = useCallback(
    () => buttonRef.current?.addEventListener('keydown', onKeyPress),
    [textToCopy, setJustCopied]
  )

  const onBlur = useCallback(
    () => buttonRef.current?.removeEventListener('keydown', onKeyPress),
    [textToCopy, setJustCopied]
  )

  useEffect(() => {
    if (!justCopied) {
      return
    }

    const justCopiedTimeout = 1000
    const timer = setTimeout(() => setJustCopied(false), justCopiedTimeout)
    return () => clearTimeout(timer)
  }, [justCopied, setJustCopied])

  return (
    <button
      ref={buttonRef}
      type="button"
      onClick={onClick}
      onFocus={onFocus}
      onBlur={onBlur}
      className="c-copy-text-to-clipboard"
      aria-label={`Copy "${textToCopy}" to the cliboard`}
    >
      <div className="text">{textToCopy}</div>
      <Icon icon="clipboard" alt="Copy to clipboard" />
      {justCopied ? <span className="message">Copied</span> : null}
      <span data-test-clipboard data-content={textToCopy} />
    </button>
  )
}
