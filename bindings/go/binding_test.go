package tree_sitter_tokudae_test

import (
	"testing"

	tree_sitter "github.com/tree-sitter/go-tree-sitter"
	tree_sitter_tokudae "github.com/tree-sitter/tree-sitter-tokudae/bindings/go"
)

func TestCanLoadGrammar(t *testing.T) {
	language := tree_sitter.NewLanguage(tree_sitter_tokudae.Language())
	if language == nil {
		t.Errorf("Error loading Tokudae grammar")
	}
}
