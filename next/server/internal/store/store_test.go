package store

import (
	"context"
	"errors"
	"testing"

	"github.com/jackc/pgx/v5/pgconn"
)

func TestWithTxRejectsNestedTransaction(t *testing.T) {
	err := WithTx(context.Background(), fakeBeginner{}, func(ctx context.Context, tx Tx) error {
		return WithTx(ctx, fakeBeginner{}, func(context.Context, Tx) error { return nil })
	})
	if !errors.Is(err, ErrNestedTransaction) {
		t.Fatalf("err = %v", err)
	}
}

func TestWithTxRollsBackCallbackError(t *testing.T) {
	tx := &countingTx{}
	want := errors.New("callback failed")
	err := WithTx(context.Background(), countingBeginner{tx}, func(context.Context, Tx) error { return want })
	if !errors.Is(err, want) || tx.rollbacks != 1 || tx.commits != 0 {
		t.Fatalf("err=%v commits=%d rollbacks=%d", err, tx.commits, tx.rollbacks)
	}
}

func TestWithTxCommitsSuccessfulCallbackExactlyOnce(t *testing.T) {
	tx := &countingTx{}
	if err := WithTx(context.Background(), countingBeginner{tx}, func(context.Context, Tx) error { return nil }); err != nil || tx.commits != 1 || tx.rollbacks != 0 {
		t.Fatalf("err=%v commits=%d rollbacks=%d", err, tx.commits, tx.rollbacks)
	}
}

func TestWithTxReturnsWrappedCommitErrorWithoutRollback(t *testing.T) {
	want := errors.New("commit failed")
	tx := &countingTx{commitErr: want}
	err := WithTx(context.Background(), countingBeginner{tx}, func(context.Context, Tx) error { return nil })
	if !errors.Is(err, want) || tx.commits != 1 || tx.rollbacks != 0 {
		t.Fatalf("err=%v commits=%d rollbacks=%d", err, tx.commits, tx.rollbacks)
	}
}

func TestWithTxRollsBackOnceAndRepnics(t *testing.T) {
	tx := &countingTx{}
	want := "panic value"
	defer func() {
		if got := recover(); got != want {
			t.Fatalf("panic=%v", got)
		}
		if tx.rollbacks != 1 || tx.commits != 0 {
			t.Fatalf("commits=%d rollbacks=%d", tx.commits, tx.rollbacks)
		}
	}()
	_ = WithTx(context.Background(), countingBeginner{tx}, func(context.Context, Tx) error { panic(want) })
}

type fakeBeginner struct{}

func (fakeBeginner) Begin(context.Context) (Tx, error) { return &fakeTx{}, nil }

type fakeTx struct{}

func (*fakeTx) Commit(context.Context) error   { return nil }
func (*fakeTx) Rollback(context.Context) error { return nil }
func (*fakeTx) Exec(context.Context, string, ...any) (pgconn.CommandTag, error) {
	return pgconn.CommandTag{}, nil
}

type countingBeginner struct{ tx *countingTx }

func (b countingBeginner) Begin(context.Context) (Tx, error) { return b.tx, nil }

type countingTx struct {
	commits, rollbacks int
	commitErr          error
}

func (t *countingTx) Commit(context.Context) error   { t.commits++; return t.commitErr }
func (t *countingTx) Rollback(context.Context) error { t.rollbacks++; return nil }
func (t *countingTx) Exec(context.Context, string, ...any) (pgconn.CommandTag, error) {
	return pgconn.CommandTag{}, nil
}
